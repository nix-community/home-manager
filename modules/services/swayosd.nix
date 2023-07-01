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

    maxVolume = mkOption {
      type = types.nullOr types.ints.unsigned;
      default = null;
      example = 120;
      description = ''
        Sets the maximum volume.
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
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
          Documentation = "man:swayosd(1)";
        };

        Service = {
          Type = "simple";
          ExecStart = "${cfg.package}/bin/swayosd"
            + (optionalString (cfg.maxVolume != null)
              " --max-volume ${toString cfg.maxVolume}");
          Restart = "always";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
