{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.timewarrior;
  taskCfg = config.programs.taskwarrior;
in
{
  options.programs.timewarrior = {
    enable = lib.mkEnableOption "Timewarrior";
    package = lib.mkPackageOption pkgs "timewarrior" { };
    taskwarrior.enable = lib.mkOption {
      type = lib.types.bool;
      default = taskCfg.enable;
      description = ''
        Whether to enable the on-modify hook for Taskwarrior.
        See <https://timewarrior.net/docs/taskwarrior/>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file."${taskCfg.dataLocation}/hooks/on-modify.timewarrior" = lib.mkIf cfg.taskwarrior.enable {
      executable = true;
      source = "${cfg.package}/share/doc/timew/ext/on-modify.timewarrior";
    };
  };

  meta.maintainers = with lib.maintainers; [ prince213 ];
}
