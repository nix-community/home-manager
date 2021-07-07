{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.keynav;

in {
  options.services.keynav = { enable = mkEnableOption "keynav"; };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.keynav" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.keynav = {
      Unit = {
        Description = "keynav";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.keynav}/bin/keynav";
        RestartSec = 3;
        Restart = "always";
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
