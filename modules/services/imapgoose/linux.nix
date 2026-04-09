{
  config,
  lib,
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
      Unit.Description = "imapgoose mail synchronization";

      Service = {
        Type = "oneshot";
        ExecStart = "${lib.getExe pkg} -c ${configFile}";
      }
      // lib.optionalAttrs (cfg.preExec != null) { ExecStartPre = cfg.preExec; }
      // lib.optionalAttrs (cfg.postExec != null) { ExecStartPost = cfg.postExec; };
    };

    systemd.user.timers.imapgoose = {
      Unit.Description = "imapgoose mail synchronization";

      Timer = {
        OnCalendar = cfg.frequency;
        Unit = "imapgoose.service";
      };

      Install.WantedBy = [ "timers.target" ];
    };
  };
}
