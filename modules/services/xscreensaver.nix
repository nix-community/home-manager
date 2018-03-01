{ config, lib, pkgs, ... }:

with lib;

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.xscreensaver = {
      enable = mkEnableOption "XScreenSaver";
    };
  };

  config = mkIf config.services.xscreensaver.enable {
    # To make the xscreensaver-command tool available.
    home.packages = [ pkgs.xscreensaver ];

    systemd.user.services.xscreensaver = {
        Unit = {
          Description = "XScreenSaver";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs.xscreensaver}/bin/xscreensaver -no-splash";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
    };
  };
}
