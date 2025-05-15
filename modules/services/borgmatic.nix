{
  config,
  lib,
  pkgs,
  ...
}:
let
  serviceConfig = config.services.borgmatic;
  programConfig = config.programs.borgmatic;
in
{
  meta.maintainers = [ lib.maintainers.DamienCassou ];

  options = {
    services.borgmatic = {
      enable = lib.mkEnableOption "Borgmatic service";

      frequency = lib.mkOption {
        type = lib.types.str;
        default = "hourly";
        description = ''
          How often to run borgmatic when
          `services.borgmatic.enable = true`.
          This value is passed to the systemd timer configuration as
          the onCalendar option. See
          {manpage}`systemd.time(7)`
          for more information about the format.
        '';
      };
    };
  };

  config = lib.mkIf serviceConfig.enable (
    lib.mkMerge [
      (lib.mkIf pkgs.stdenv.isLinux {
        systemd.user = {
          services.borgmatic = {
            Unit = {
              Description = "borgmatic backup";
              # Prevent borgmatic from running unless the machine is
              # plugged into power:
              ConditionACPower = true;
            };
            Service = {
              Type = "oneshot";

              # Lower CPU and I/O priority:
              Nice = 19;
              IOSchedulingClass = "best-effort";
              IOSchedulingPriority = 7;
              IOWeight = 100;

              Restart = "no";
              LogRateLimitIntervalSec = 0;

              # Delay start to prevent backups running during boot:
              ExecStartPre = "${pkgs.coreutils}/bin/sleep 3m";

              ExecStart = ''
                ${pkgs.systemd}/bin/systemd-inhibit \
                  --who="borgmatic" \
                  --what="sleep:shutdown" \
                  --why="Prevent interrupting scheduled backup" \
                  ${programConfig.package}/bin/borgmatic \
                    --stats \
                    --verbosity -1 \
                    --list \
                    --syslog-verbosity 1
              '';
            };
          };

          timers.borgmatic = {
            Unit.Description = "Run borgmatic backup";
            Timer = {
              OnCalendar = serviceConfig.frequency;
              Persistent = true;
              RandomizedDelaySec = "10m";
            };
            Install.WantedBy = [ "timers.target" ];
          };
        };
      })

      (lib.mkIf pkgs.stdenv.isDarwin {
        assertions = [
          (lib.hm.darwin.assertInterval "services.borgmatic.frequency" serviceConfig.frequency pkgs)
        ];

        launchd.agents.borgmatic = {
          enable = true;
          config = {
            ProgramArguments = [
              (lib.getExe programConfig.package)
              "--stats"
              "--list"
            ];
            ProcessType = "Background";
            StartCalendarInterval = lib.hm.darwin.mkCalendarInterval serviceConfig.frequency;
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/borgmatic/launchd-stdout.log";
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/borgmatic/launchd-stderr.log";
          };
        };
      })
    ]
  );
}
