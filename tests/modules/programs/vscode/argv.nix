package:

{
  pkgs,
  ...
}:

let
  argvPath = ".vscode/argv.json";

  content = ''
    {
      "enable-crash-reporter": false
    }
  '';

  expectedArgvSettings = pkgs.writeText "custom-argv.json" content;
in

{
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
