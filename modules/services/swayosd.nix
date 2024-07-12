{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.swayosd;

in {
  meta.maintainers = [ hm.maintainers.pltanton ];

  options.services.swayosd = {
    enable = mkEnableOption ''
      swayosd, a GTK based on screen display for keyboard shortcuts like
      caps-lock and volume'';

    package = mkPackageOption pkgs "swayosd" { };

    topMargin = mkOption {
      type = types.nullOr (types.addCheck types.float (f: f >= 0.0 && f <= 1.0)
        // {
          description = "float between 0.0 and 1.0 (inclusive)";
        });
      default = null;
      example = 1.0;
      description = "OSD margin from top edge (0.5 would be screen center).";
    };

    stylePath = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/etc/xdg/swayosd/style.css";
      description = ''
        Use a custom Stylesheet file instead of looking for one.
      '';
    };

    display = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "eDP-1";
      description = ''
        X display to use.
      '';
    };

    systemdTarget = mkOption {
      type = types.str;
      default = "graphical-session.target";
      example = "sway-session.target";
      description = ''
        Systemd target to bind to.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.swayosd" pkgs platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user = {
      services.swayosd = {
        Unit = {
          Description = "Volume/backlight OSD indicator";
          PartOf = [ cfg.systemdTarget ];
          After = [ cfg.systemdTarget ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
          Documentation = "man:swayosd(1)";
        };

        Service = {
          Type = "simple";
          ExecStart = "${cfg.package}/bin/swayosd-server"
            + (optionalString (cfg.display != null) " --display ${cfg.display}")
            + (optionalString (cfg.stylePath != null)
              " --style ${escapeShellArg cfg.stylePath}")
            + (optionalString (cfg.topMargin != null)
              " --top-margin ${toString cfg.topMargin}");
          Restart = "always";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
