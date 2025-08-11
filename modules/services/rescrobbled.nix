{
  lib,
  pkgs,
  config,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
  cfg = config.services.rescrobbled;
in
{
  meta.maintainers = [ lib.maintainers.awwpotato ];

  options.services.rescrobbled = {
    enable = lib.mkEnableOption "rescrobbled, a MPRIS music scrobbler daemon";
    package = lib.mkPackageOption pkgs "rescrobbled" { };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/rescrobbled/config.toml`
        See <https://github.com/InputUsername/rescrobbled#configuration> for
        the full list of options.
      '';
      example = {
        lastfm-key = "Last.fm API key";
        lastfm-secret = "Last.fm API secret";
        min-play-time = 0;
        player-whitelist = [ "Player MPRIS identity or bus name" ];
        filter-script = "path/to/script";
        use-track-start-timestamp = false;

        listenbrainz = [
          {
            url = "Custom API URL";
            token = "User token";
          }
        ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.rescrobbled" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."rescrobbled/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "rescrobbled-config" cfg.settings;
    };

    systemd.user.services.rescrobbled = {
      Unit = {
        Description = "An MPRIS scrobbler";
        Documentation = "https://github.com/InputUsername/rescrobbled";
        Wants = [ "network-online.target" ];
        After = [ "network-online.target" ];
      };

      Service.ExecStart = lib.getExe cfg.package;

      Install.WantedBy = [ "default.target" ];
    };
  };
}
