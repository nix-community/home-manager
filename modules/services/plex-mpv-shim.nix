{ config, lib, pkgs, ... }:

with lib;

let

  jsonFormat = pkgs.formats.json { };
  cfg = config.services.plex-mpv-shim;

in {
  meta.maintainers = [ maintainers.starcraft66 ];

  options = {
    services.plex-mpv-shim = {
      enable = mkEnableOption "Plex mpv shim";

      package = mkOption {
        type = types.package;
        default = pkgs.plex-mpv-shim;
        defaultText = literalExpression "pkgs.plex-mpv-shim";
        description = "The package to use for the Plex mpv shim.";
      };

      settings = mkOption {
        type = jsonFormat.type;
        default = { };
        example = literalExpression ''
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

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.plex-mpv-shim" pkgs
        lib.platforms.linux)
    ];

    xdg.configFile."plex-mpv-shim/conf.json" = mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "conf.json" cfg.settings;
    };

    systemd.user.services.plex-mpv-shim = {
      Unit = {
        Description = "Plex mpv shim";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = { ExecStart = "${cfg.package}/bin/plex-mpv-shim"; };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
