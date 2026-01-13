{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption mkMerge;
  assertions = import ../assertions.nix { inherit lib; };

  cfg = config.services.podman;
in
{
  options.services.podman = {
    autoUpdate = {
      enable = mkOption {
        type = lib.types.bool;
        default = pkgs.stdenv.hostPlatform.isLinux;
        description = "Automatically update the podman images.";
      };

      onCalendar = mkOption {
        type = lib.types.str;
        default = lib.optionalString pkgs.stdenv.hostPlatform.isLinux "Sun *-*-* 00:00";
        description = ''
          The systemd `OnCalendar` expression for the update. See
          {manpage}`systemd.time(7)` for a description of the format.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        (assertions.assertPlatform "services.podman.networks" config pkgs lib.platforms.linux)
      ];
    }
    (mkIf pkgs.stdenv.hostPlatform.isLinux (mkMerge [
      (mkIf cfg.autoUpdate.enable {
        systemd.user.services."podman-auto-update" = {
          Unit = {
            Description = "Podman auto-update service";
            Documentation = "man:podman-auto-update(1)";
            Wants = [ "network-online.target" ];
            After = [ "network-online.target" ];
          };

          Service = {
            Type = "oneshot";
            Environment = "PATH=${
              builtins.concatStringsSep ":" [
                "/run/wrappers/bin"
                "/run/current-system/sw/bin"
                "${config.home.homeDirectory}/.nix-profile/bin"
              ]
            }";
            ExecStart = "${cfg.package}/bin/podman auto-update";
            ExecStartPost = "${cfg.package}/bin/podman image prune -f";
            TimeoutStartSec = "300s";
            TimeoutStopSec = "10s";
          };
        };

        systemd.user.timers."podman-auto-update" = {
          Unit = {
            Description = "Podman auto-update timer";
          };

          Timer = {
            OnCalendar = cfg.autoUpdate.onCalendar;
            RandomizedDelaySec = 300;
            Persistent = true;
          };

          Install = {
            WantedBy = [ "timers.target" ];
          };
        };
      })
      {
        xdg.configFile."systemd/user/podman-user-wait-network-online.service.d/50-exec-search-path.conf".text =
          ''
            [Service]
            ExecSearchPath=${
              lib.makeBinPath (
                with pkgs;
                [
                  bashInteractive
                  systemd
                  coreutils
                ]
              )
            }:/bin
          '';
      }
    ]))
  ]);
}
