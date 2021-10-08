{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.status-notifier-watcher;

in {
  meta.maintainers = [ maintainers.pltanton ];

  options = {
    services.status-notifier-watcher = {
      enable = mkEnableOption "Status Notifier Watcher";

      package = mkOption {
        default = pkgs.haskellPackages.status-notifier-item;
        defaultText =
          literalExpression "pkgs.haskellPackages.status-notifier-item";
        type = types.package;
        example = literalExpression "pkgs.haskellPackages.status-notifier-item";
        description =
          "The package to use for the status notifier watcher binary.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.status-notifier-watcher" pkgs
        lib.platforms.linux)
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

      Install = { WantedBy = [ "tray.target" "taffybar.service" ]; };
    };
  };
}
