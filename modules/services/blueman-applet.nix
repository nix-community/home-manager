{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    services.blueman-applet = {
      enable = mkEnableOption ''
        Blueman applet.

        Note, for the applet to work, 'blueman' package should also be installed system-wide
        since it requires running 'blueman-mechanism' service activated via dbus.
        You can add it to the dbus packages in system configuration:

          services.dbus.packages = [ pkgs.blueman ];
      '';
    };
  };

  config = mkIf config.services.blueman-applet.enable {
    systemd.user.services.blueman-applet = {
        Unit = {
          Description = "Blueman applet";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs.blueman}/bin/blueman-applet";
        };
    };
  };
}
