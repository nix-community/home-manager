{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.status-notifier-watcher;

in

{
  meta.maintainers = [ maintainers.pltanton ];

  options = {
    services.status-notifier-watcher = {
      enable = mkEnableOption "Status Notifier Watcher";

      package = mkOption {
        default = pkgs.haskellPackages.status-notifier-item;
        defaultText = literalExample "pkgs.haskellPackages.status-notifier-item";
        type = types.package;
        example = literalExample "pkgs.haskellPackages.status-notifier-item";
        description = "The package to use for the status notifier watcher binary.";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.status-notifier-watcher = {
        Unit = {
          Description = "SNI watcher";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
          Before = [ "taffybar.service" ];
        };

        Service = {
          ExecStart = "${cfg.package}/bin/status-notifier-watcher";
        };

        Install = {
          WantedBy = [ "graphical-session.target" "taffybar.service" ];
        };
    };
  };
}
