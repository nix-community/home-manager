{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    services.blueman-applet = {
      enable = mkEnableOption "Blueman applet";
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
