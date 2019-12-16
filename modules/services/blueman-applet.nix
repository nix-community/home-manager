{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    services.blueman-applet = {
      enable = mkEnableOption ''
        Blueman applet.

        Note, for the applet to work, 'blueman' service should be enabled system-wide
        since it requires running 'blueman-mechanism' service activated.
        You can enable it in system configuration:

          services.blueman.enable = true;
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
