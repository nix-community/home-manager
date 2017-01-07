{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    services.network-manager-applet = {
      enable = mkEnableOption "the Network Manager applet";
    };
  };

  config = mkIf config.services.network-manager-applet.enable {
    systemd.user.services.network-manager-applet = {
        Unit = {
          Description = "Network Manager applet";
        };

        Install = {
          WantedBy = [ "xorg.target" ];
        };

        Service = {
          ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --sm-disable";
        };
    };
  };
}
