{ config, lib, pkgs, ... }:

with lib;

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.syncthing = {
      enable = mkEnableOption "Syncthing continuous file synchronization";

      tray = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable QSyncthingTray service.";
      };
    };
  };

  config = mkMerge [
    (mkIf config.services.syncthing.enable {
      home.packages = [ (getOutput "man" pkgs.syncthing) ];

      systemd.user.services = {
        syncthing = {
          Unit = {
            Description =
              "Syncthing - Open Source Continuous File Synchronization";
            Documentation = "man:syncthing(1)";
            After = [ "network.target" ];
          };

          Service = {
            ExecStart =
              "${pkgs.syncthing}/bin/syncthing -no-browser -no-restart -logflags=0";
            Restart = "on-failure";
            SuccessExitStatus = [ 3 4 ];
            RestartForceExitStatus = [ 3 4 ];
          };

          Install = { WantedBy = [ "default.target" ]; };
        };
      };
    })

    (mkIf config.services.syncthing.tray {
      systemd.user.services = {
        qsyncthingtray = {
          Unit = {
            Description = "QSyncthingTray";
            After = [
              "graphical-session-pre.target"
              "polybar.service"
              "taffybar.service"
              "stalonetray.service"
            ];
            PartOf = [ "graphical-session.target" ];
          };

          Service = {
            Environment = "PATH=${config.home.profileDirectory}/bin";
            ExecStart = "${pkgs.qsyncthingtray}/bin/QSyncthingTray";
          };

          Install = { WantedBy = [ "graphical-session.target" ]; };
        };
      };
    })
  ];
}
