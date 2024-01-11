{ config, lib, pkgs, ... }:

let

  inherit (lib.options) mkEnableOption mkPackageOption mkOption;
  inherit (lib.modules) mkIf;

  cfg = config.services.listenbrainz-mpd;

  tomlFormat = pkgs.formats.toml { };

in {
  meta.maintainers = [ lib.maintainers.Scrumplex ];

  options.services.listenbrainz-mpd = {
    enable = mkEnableOption "listenbrainz-mpd";

    package = mkPackageOption pkgs "listenbrainz-mpd" { };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      description = ''
        Configuration for listenbrainz-mpd written to
        {file}`$XDG_CONFIG_HOME/listenbrainz-mpd/config.toml`.
      '';
      example = { submission.tokenFile = "/run/secrets/listenbrainz-mpd"; };
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services."listenbrainz-mpd" = {
      Unit = {
        Description = "ListenBrainz submission client for MPD";
        Documentation = "https://codeberg.org/elomatreb/listenbrainz-mpd";
        After = [ "mpd.service" ];
        Requires = [ "mpd.service" ];
      };
      Service = {
        ExecStart = "${cfg.package}/bin/listenbrainz-mpd";
        Restart = "always";
        RestartSec = 5;
        Type = if lib.versionAtLeast cfg.package.version "2.3.2" then
          "notify"
        else
          "simple";
      };
      Install.WantedBy = [ "default.target" ];
    };

    xdg.configFile."listenbrainz-mpd/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "listenbrainz-mpd.toml" cfg.settings;
    };
  };
}
