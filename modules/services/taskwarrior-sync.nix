{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.taskwarrior-sync;

in {
  meta.maintainers = with maintainers; [ minijackson pacien ];

  options.services.taskwarrior-sync = {
    enable = mkEnableOption "Taskwarrior periodic sync";

    frequency = mkOption {
      type = types.str;
      default = "*:0/5";
      description = ''
        How often to run <literal>taskwarrior sync</literal>. This
        value is passed to the systemd timer configuration as the
        <literal>OnCalendar</literal> option. See
        <citerefentry>
          <refentrytitle>systemd.time</refentrytitle>
          <manvolnum>7</manvolnum>
        </citerefentry>
        for more information about the format.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.taskwarrior-sync" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.taskwarrior-sync = {
      Unit = { Description = "Taskwarrior sync"; };
      Service = {
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        ExecStart = "${pkgs.taskwarrior}/bin/task synchronize";
      };
    };

    systemd.user.timers.taskwarrior-sync = {
      Unit = { Description = "Taskwarrior periodic sync"; };
      Timer = {
        Unit = "taskwarrior-sync.service";
        OnCalendar = cfg.frequency;
      };
      Install = { WantedBy = [ "timers.target" ]; };
    };
  };
}
