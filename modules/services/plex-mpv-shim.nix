{
  config,
  lib,
  pkgs,
  ...
}:
let

  jsonFormat = pkgs.formats.json { };
  cfg = config.services.plex-mpv-shim;

in
{
  meta.maintainers = [ lib.maintainers.starcraft66 ];

  options = {
    services.plex-mpv-shim = {
      enable = lib.mkEnableOption "Plex mpv shim";

      package = lib.mkPackageOption pkgs "plex-mpv-shim" { };

      settings = lib.mkOption {
        type = jsonFormat.type;
        default = { };
        example = lib.literalExpression ''
          {
            adaptive_transcode = false;
            allow_http = false;
            always_transcode = false;
            audio_ac3passthrough = false;
            audio_dtspassthrough = false;
            auto_play = true;
            auto_transcode = true;
          }
        '';
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/plex-mpv-shim/config.json`. See
          <https://github.com/iwalton3/plex-mpv-shim/blob/master/README.md>
          for the configuration documentation.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.plex-mpv-shim" pkgs lib.platforms.linux)
    ];

    xdg.configFile."plex-mpv-shim/conf.json" = lib.mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "conf.json" cfg.settings;
    };

    systemd.user.services.plex-mpv-shim = {
      Unit = {
        Description = "Plex mpv shim";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/plex-mpv-shim";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
