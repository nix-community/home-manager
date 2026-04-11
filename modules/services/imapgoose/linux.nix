{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.imapgoose;
  pkg = config.programs.imapgoose.package;
  configFile = "${config.xdg.configHome}/imapgoose/config.scfg";
in
{
  config = lib.mkIf cfg.enable {
    systemd.user.services.imapgoose = {
      Unit = {
        Description = "imapgoose mail synchronization";
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

        ExecStart = "${lib.getExe pkg} -c ${configFile}";
      }
      // lib.optionalAttrs (cfg.preExec != null) {
        ExecStartPre = [
          "${pkgs.coreutils}/bin/sleep 1m"
          cfg.preExec
        ];
      }
      // lib.optionalAttrs (cfg.postExec != null) {
        ExecStartPost = cfg.postExec;
      };
    };

    systemd.user.timers.imapgoose = {
      Unit.Description = "imapgoose mail synchronization";

      Timer = {
        OnCalendar = cfg.frequency;
        Unit = "imapgoose.service";
        Persistent = true;
        RandomizedDelaySec = "1m";
      };

      Install.WantedBy = [ "timers.target" ];
    };
  };
}
