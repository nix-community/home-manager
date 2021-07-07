{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.flameshot;
  package = pkgs.flameshot;

in {
  meta.maintainers = [ maintainers.hamhut1066 ];

  options = { services.flameshot = { enable = mkEnableOption "Flameshot"; }; };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.flameshot" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ package ];

    systemd.user.services.flameshot = {
      Unit = {
        Description = "Flameshot screenshot tool";
        Requires = [ "tray.target" ];
        After = [ "graphical-session-pre.target" "tray.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        Environment = "PATH=${config.home.profileDirectory}/bin";
        ExecStart = "${package}/bin/flameshot";
        Restart = "on-abort";
      };
    };
  };
}
