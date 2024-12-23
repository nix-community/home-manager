{ config, lib, nixosConfig, pkgs, ... }:

let
  inherit (lib) types;

  cfg = config.services.librespot;
  args = lib.pipe cfg.settings [
    builtins.attrNames
    (builtins.concatMap (k:
      let v = cfg.settings.${k};
      in if v == null || v == false then
        [ ]
      else if v == true then
        [ "--${k}" ]
      else
        [ "--${k}=${toString v}" ]))
    lib.escapeShellArgs
  ];
  script = pkgs.writeShellScript "librespot" ''
    exec '${cfg.package}/bin/librespot' ${args}
  '';
in {
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
        freeformType = let t = types;
        in t.attrsOf (t.nullOr (t.oneOf [ t.bool t.str t.int t.path ]));

        options = {
          cache = lib.mkOption {
            default = "${config.xdg.cacheHome}/librespot";
            type = types.nullOr types.path;
            description =
              "Path to a directory where files will be cached after downloading.";
          };

          system-cache = lib.mkOption {
            default = "${config.xdg.stateHome}/librespot";
            type = types.nullOr types.path;
            description =
              "Path to a directory where system files (credentials, volume) will be cached.";
          };
        };
      };
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    systemd.user.services.librespot = {
      Unit = { Description = "Librespot (an open source Spotify client)"; };

      Install.WantedBy = [ "default.target" ];

      Service = {
        ExecStart = script;
        Restart = "always";
        RestartSec = 12;
      };
    };
  };
}
