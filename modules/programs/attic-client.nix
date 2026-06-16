{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    ;

  cfg = config.programs.attic-client;

  settingsFormat = pkgs.formats.toml { };
in
{
  options.programs.attic-client = {
    enable = lib.mkEnableOption "the attic binary cache client";

    package = lib.mkPackageOption pkgs "attic-client" {
      nullable = true;
    };

    settings = mkOption {
      inherit (settingsFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          default-server = "myserver";
          servers.myserver = {
            endpoint = "https://myserver.org";
            token-file = "/run/secrets/attic-token";
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/attic/config.toml`.

        See <https://github.com/zhaofengli/attic> for the available options.
      '';
    };

    watchStore = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "mycacheserver:mycache" ];
      description = ''
        Caches to push new store paths to via `attic watch-store`.
        Format: `server:cache` (or just `cache` to use the default server).

        This relies on systemd and is only supported on Linux.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.watchStore == [ ] || pkgs.stdenv.hostPlatform.isLinux;
        message = "programs.attic-client.watchStore requires systemd and is only supported on Linux.";
      }
      {
        assertion = cfg.watchStore == [ ] || cfg.package != null;
        message = "programs.attic-client.watchStore requires programs.attic-client.package to be set.";
      }
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."attic/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = settingsFormat.generate "attic-config.toml" cfg.settings;
    };

    systemd.user.services = lib.mkIf (cfg.watchStore != [ ]) (
      lib.listToAttrs (
        map (
          cache:
          lib.nameValuePair "attic-watch-store--${lib.replaceStrings [ ":" ] [ "-" ] cache}" {
            Unit.Description = "Push new store paths to the attic cache ${cache}";

            Install.WantedBy = [ "default.target" ];

            Service = {
              ExecStart = "${lib.getExe cfg.package} watch-store ${cache}";
              Restart = "always";
              RestartSec = 30;
            };
          }
        ) cfg.watchStore
      )
    );
  };

  meta.maintainers = [ lib.maintainers.swarsel ];
}
