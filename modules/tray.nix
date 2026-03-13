{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.tray;

  watcherService = "tray-watcher.service";

  watcherDeps = lib.optional (
    cfg.waitForWatcher != "none" && cfg.watcherBusName != null
  ) watcherService;

  sniWatcherAfter = watcherDeps;
  sniWatcherWants = if cfg.waitForWatcher == "prefer" then watcherDeps else [ ];
  sniWatcherRequires = if cfg.waitForWatcher == "require" then watcherDeps else [ ];
in
{
  options.services.tray = {
    waitForWatcher = lib.mkOption {
      type = lib.types.enum [
        "none"
        "prefer"
        "require"
      ];
      default = "prefer";
      description = ''
        Controls whether StatusNotifierItem (SNI) tray services should wait for a
        watcher to be available on D-Bus.

        - `none`: do not add any watcher dependency.
        - `prefer`: add `Wants=` and `After=` on `tray-watcher.service` so
          services wait for the watcher if it starts, but continue if it fails.
        - `require`: add `Requires=` and `After=` on `tray-watcher.service` so
          services only start when the watcher is available.

        The watcher readiness is determined by D-Bus ownership of
        `org.kde.StatusNotifierWatcher` (e.g. a `Type=dbus` service).
      '';
    };

    watcherBusName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "org.kde.StatusNotifierWatcher";
      description = ''
        The D-Bus name used to detect watcher readiness when
        `waitForWatcher` is enabled.

        Set to `null` to disable watcher readiness checks entirely.
      '';
    };

    watcherTimeoutSec = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      example = 15;
      description = ''
        Timeout in seconds for waiting on the watcher D-Bus name. When `null`,
        systemd's default `TimeoutStartSec` applies.
      '';
    };
  };

  config = {
    lib.tray = {
      targets = {
        main = "tray.target";
        sni = "tray-sni.target";
        xembed = "tray-xembed.target";
      };
      preferSni = config.xsession.preferStatusNotifierItems;
      preferredTarget =
        if config.xsession.preferStatusNotifierItems then "tray-sni.target" else "tray-xembed.target";
      watcherService = watcherService;
      sniWatcherAfter = sniWatcherAfter;
      sniWatcherWants = sniWatcherWants;
      sniWatcherRequires = sniWatcherRequires;
    };

    systemd.user = lib.mkIf config.systemd.user.enable {
      services.tray-watcher = lib.mkIf (cfg.waitForWatcher != "none" && cfg.watcherBusName != null) (
        let
          script = pkgs.writeShellScript "hm-wait-sni-watcher" ''
            set -eu

            busctl=${lib.getExe' pkgs.systemd "busctl"}
            name=${lib.escapeShellArg cfg.watcherBusName}

            while true; do
              out="$($busctl --user call org.freedesktop.DBus /org/freedesktop/DBus \
                org.freedesktop.DBus NameHasOwner s "$name" 2>/dev/null || true)"
              set -- $out
              if [ "''${2:-}" = "true" ]; then
                exit 0
              fi
              sleep 0.2
            done
          '';
        in
        {
          Unit = {
            Description = "Wait for SNI watcher on D-Bus";
          };

          Service = {
            Type = "oneshot";
            ExecStart = "${script}";
            RemainAfterExit = true;
          }
          // lib.optionalAttrs (cfg.watcherTimeoutSec != null) {
            TimeoutStartSec = cfg.watcherTimeoutSec;
          };
        }
      );

      targets = {
        tray = {
          Unit = {
            Description = "Home Manager System Tray";
            Requires = [ "graphical-session-pre.target" ];
            Wants = [
              "tray-sni.target"
              "tray-xembed.target"
            ];
          };
        };

        tray-sni = {
          Unit = {
            Description = "Home Manager SNI Tray";
            Requires = [ "graphical-session-pre.target" ];
            PartOf = [ "tray.target" ];
          };
        };

        tray-xembed = {
          Unit = {
            Description = "Home Manager XEmbed Tray";
            Requires = [ "graphical-session-pre.target" ];
            PartOf = [ "tray.target" ];
          };
        };
      };
    };
  };
}
