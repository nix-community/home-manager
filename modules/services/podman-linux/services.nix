{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.podman;
in {
  options.services.podman = {

    auto-update = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Automatically update the podman images.";
      };

      OnCalendar = mkOption {
        type = types.str;
        default = "Sun *-*-* 00:00";
        description = "Systemd OnCalendar expression for the update";
      };
    };

  };

  config = mkMerge [
    ( mkIf cfg.auto-update.enable {
      systemd.user.services."podman-auto-update" = {
        Unit = {
          Description = "Podman auto-update service";
          Documentation = "man:podman-auto-update(1)";
          Wants = [ "network-online.target" ];
          After = [ "network-online.target" ];
        };
        Service = {
          Type = "oneshot";
          Environment = "PATH=/run/wrappers/bin:/run/current-system/sw/bin:${config.home.homeDirectory}/.nix-profile/bin";
          ExecStart = "${pkgs.podman}/bin/podman auto-update";
          ExecStartPost = "${pkgs.podman}/bin/podman image prune -f";
          TimeoutStartSec = "300s";
          TimeoutStopSec = "10s";
        };
      };

      systemd.user.timers."podman-auto-update" = {
        Unit = {
          Description = "Podman auto-update timer";
        };
        Timer = {
          OnCalendar = cfg.auto-update.OnCalendar;
          RandomizedDelaySec = 300;
          Persistent = true;
        };
        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    })
  ];
}
