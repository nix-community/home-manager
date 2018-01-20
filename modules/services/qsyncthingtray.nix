{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    services.qsyncthingtray = {
      enable = mkEnableOption "QSyncthingTray";
    };
  };

  config = mkIf config.services.qsyncthingtray.enable {
    systemd.user.services.qsyncthingtray = {
        Unit = {
          Description = "QSyncthingTray";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs.qsyncthingtray}/bin/QSyncthingTray";
        };
    };
  };
}
