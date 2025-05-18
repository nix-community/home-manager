{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) types;

  # Like lib.mapAttrsToList, but concatenate the results
  concatMapAttrsToList =
    f: attrs: builtins.concatMap (name: f name attrs.${name}) (builtins.attrNames attrs);

  cfg = config.services.librespot;
in
{
  options.services.librespot = {
    enable = lib.mkEnableOption "Librespot (Spotify Connect speaker daemon)";

    package = lib.mkPackageOption pkgs "librespot" { };

    settings = lib.mkOption {
      description = ''
        Command-line arguments to pass to librespot.

        Boolean values render as a flag if true, and nothing if false.
        Null values are ignored.
        All other values are rendered as options with an argument.
      '';
      type = types.submodule {
        freeformType =
          let
            t = types;
          in
          t.attrsOf (
            t.nullOr (
              t.oneOf [
                t.bool
                t.str
                t.int
                t.path
              ]
            )
          );

        options = {
          cache = lib.mkOption {
            default = "${config.xdg.cacheHome}/librespot";
            defaultText = "$XDG_CACHE_HOME/librespot";
            type = types.nullOr types.path;
            description = "Path to a directory where files will be cached after downloading.";
          };

          system-cache = lib.mkOption {
            default = "${config.xdg.stateHome}/librespot";
            defaultText = "$XDG_STATE_HOME/librespot";
            type = types.nullOr types.path;
            description = "Path to a directory where system files (credentials, volume) will be cached.";
          };
        };
      };
      default = { };
    };

    args = lib.mkOption {
      type = types.listOf types.str;
      internal = true;
      description = ''
        Command-line arguments to pass to the service.

        This is generated from {option}`services.librespot.settings`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.librespot = {
      args = concatMapAttrsToList (
        k: v:
        if v == null || v == false then
          [ ]
        else if v == true then
          [ "--${k}" ]
        else
          [ "--${k}=${toString v}" ]
      ) cfg.settings;
    };

    home.packages = [ cfg.package ];

    systemd.user.services.librespot = {
      Unit = {
        Description = "Librespot (an open source Spotify client)";
      };

      Install.WantedBy = [ "default.target" ];

      Service = {
        ExecStart = pkgs.writeShellScript "librespot" ''
          exec '${cfg.package}/bin/librespot' ${lib.escapeShellArgs cfg.args}
        '';
        Restart = "always";
        RestartSec = 12;
      };
    };
  };
}
