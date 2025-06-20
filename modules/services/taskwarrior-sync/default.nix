{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.services.taskwarrior-sync;

in
{
  meta.maintainers = with lib.maintainers; [
    euxane
    minijackson
  ];

  options.services.taskwarrior-sync = {
    enable = lib.mkEnableOption "Taskwarrior periodic sync";

    package = lib.mkPackageOption pkgs "taskwarrior" { example = "pkgs.taskwarrior3"; };

    frequency = lib.mkOption {
      type = lib.types.str;
      default = "*:0/5";
      description = ''
        How often to run `taskwarrior sync`. This
        value is passed to the systemd timer configuration as the
        `OnCalendar` option. See
        {manpage}`systemd.time(7)`
        for more information about the format.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.taskwarrior-sync" pkgs lib.platforms.linux)
    ];

    systemd.user.services.taskwarrior-sync = {
      Unit = {
        Description = "Taskwarrior sync";
      };
      Service = {
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        ExecStart = "${cfg.package}/bin/task synchronize";
      };
    };

    systemd.user.timers.taskwarrior-sync = {
      Unit = {
        Description = "Taskwarrior periodic sync";
      };
      Timer = {
        Unit = "taskwarrior-sync.service";
        OnCalendar = cfg.frequency;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
