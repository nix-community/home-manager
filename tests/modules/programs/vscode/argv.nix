package:

{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.programs.vscode;
  willUseIfd = package.pname != "vscode";

  argvPath = "${cfg.nameShort}/argv.json";

  content = ''
    {
      "enable-crash-reporter": false
    }
  '';

  expectedArgvSettings = pkgs.writeText "custom-argv.json" content;
in

lib.mkIf (willUseIfd -> config.test.enableLegacyIfd) {
  programs.vscode = {
    enable = true;
    inherit package;
    argvSettings.enable-crash-reporter = false;
  };

  argv.script = ''
    assertFileExists "home-files/${argvPath}"
    assertFileContent "home-files/${argvPath}" "${expectedArgvSettings}"
  '';
}
