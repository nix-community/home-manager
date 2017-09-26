{ config, lib, pkgs, ... }:

with lib;

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.network-manager-applet = {
      enable = mkEnableOption "the Network Manager applet";
    };
  };

  config = mkIf config.services.network-manager-applet.enable {
    systemd.user.services.network-manager-applet = {
        Unit = {
          Description = "Network Manager applet";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --sm-disable";
        };
    };
  };
}
