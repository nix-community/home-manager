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
    launchd.agents.imapgoose = {
      enable = true;
      config = {
        ProgramArguments = programArguments;
        StartInterval = cfg.startInterval;
        ProcessType = "Background";
        RunAtLoad = true;
      };
    };
  };
}
