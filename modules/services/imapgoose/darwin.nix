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

  runScript = pkgs.writeShellScript "imapgoose-run" (
    lib.optionalString (cfg.preExec != null) ''
      ${cfg.preExec}
    ''
    + ''
      ${lib.getExe pkg} -c ${configFile}
    ''
    + lib.optionalString (cfg.postExec != null) ''
      ${cfg.postExec}
    ''
  );

  programArguments =
    if cfg.preExec != null || cfg.postExec != null then
      [ "${runScript}" ]
    else
      [
        "${lib.getExe pkg}"
        "-c"
        configFile
      ];
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.darwin.assertInterval "services.imapgoose.frequency" cfg.frequency pkgs)
    ];

    launchd.agents.imapgoose = {
      enable = true;
      config = {
        ProgramArguments = programArguments;
        ProcessType = "Background";
        Nice = 19;
        LowPriorityIO = true;
        StartCalendarInterval = lib.hm.darwin.mkCalendarInterval cfg.frequency;
        RunAtLoad = true;
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/imapgoose/launchd-stdout.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/imapgoose/launchd-stderr.log";
      };
    };
  };
}
