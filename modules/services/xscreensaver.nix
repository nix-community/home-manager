{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    services.xscreensaver = {
      enable = mkEnableOption "XScreenSaver";
    };
  };

  config = mkIf config.services.xscreensaver.enable {
    systemd.user.services.xscreensaver = {
        Unit = {
          Description = "XScreenSaver";
        };

        Service = {
          ExecStart = "${pkgs.xscreensaver}/bin/xscreensaver -no-splash";
        };

        Install = {
          WantedBy = [ "xorg.target" ];
        };
    };
  };
}
