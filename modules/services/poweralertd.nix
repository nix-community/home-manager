{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.poweralertd;

in {
  meta.maintainers = [ maintainers.thibautmarty ];

  options.services.poweralertd.enable =
    mkEnableOption "the Upower-powered power alerterd";

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.poweralertd" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.poweralertd = {
      Unit = {
        Description = "UPower-powered power alerter";
        Documentation = "man:poweralertd(1)";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.poweralertd}/bin/poweralertd";
        Restart = "always";
      };
    };
  };
}
