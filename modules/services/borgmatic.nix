{ config, lib, pkgs, ... }:

with lib;

let
  serviceConfig = config.services.borgmatic;
  programConfig = config.programs.borgmatic;
in {
  meta.maintainers = [ maintainers.DamienCassou ];

  options = {
    services.borgmatic = {
      enable = mkEnableOption "Borgmatic service";

      frequency = mkOption {
        type = types.str;
        default = "hourly";
        description = ''
          How often to run borgmatic when
          <code language="nix">services.borgmatic.enable = true</code>.
          This value is passed to the systemd timer configuration as
          the onCalendar option. See
          <citerefentry>
            <refentrytitle>systemd.time</refentrytitle>
            <manvolnum>7</manvolnum>
          </citerefentry>
          for more information about the format.
        '';
      };
    };
  };

  config = mkIf serviceConfig.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.borgmatic" pkgs
        lib.platforms.linux)
    ];

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
          CPUSchedulingPolicy = "batch";
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
  };
}
