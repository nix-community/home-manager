{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.status-notifier-watcher;
in
{
  meta.maintainers = [ lib.hm.maintainers.pltanton ];

  options = {
    services.status-notifier-watcher = {
      enable = lib.mkEnableOption "Status Notifier Watcher";

      package = lib.mkPackageOption pkgs.haskellPackages "status-notifier-item" {
        pkgsText = "pkgs.haskellPackages";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.status-notifier-watcher" pkgs lib.platforms.linux)
    ];

    systemd.user.services.status-notifier-watcher = {
      Unit = {
        Description = "SNI watcher";
        PartOf = [ "tray.target" ];
        Before = [ "taffybar.service" ];
      };

      Service = {
        Type = "dbus";
        BusName = "org.kde.StatusNotifierWatcher";
        ExecStart = "${cfg.package}/bin/status-notifier-watcher";
      };

      Install = {
        WantedBy = [
          "tray.target"
          "taffybar.service"
        ];
      };
    };
  };
}
