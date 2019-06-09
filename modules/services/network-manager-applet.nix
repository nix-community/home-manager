{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.network-manager-applet;

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.network-manager-applet = {
      enable = mkEnableOption "the Network Manager applet";
    };
  };

  config = mkIf cfg.enable {
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
        ExecStart = toString (
          [
            "${pkgs.networkmanagerapplet}/bin/nm-applet"
            "--sm-disable"
          ] ++ optional config.xsession.preferStatusNotifierItems "--indicator"
        );
      };
    };
  };
}
