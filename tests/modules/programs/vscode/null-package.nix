{
  config,
  pkgs,
  ...
}:

let
  cfg = config.programs.vscode;

  settingsPath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/${cfg.nameShort}/User/settings.json"
    else
      ".config/${cfg.nameShort}/User/settings.json";

  expectedSettings = pkgs.writeText "expected-settings.json" ''
    {
      "editor.fontSize": 14
    }
  '';
in

{
  programs.vscode = {
    enable = true;
    package = null;
    pname = "vscode";
    profiles.default.userSettings."editor.fontSize" = 14;
  };

  nmt.script = ''
    assertFileExists "home-files/${settingsPath}"
    assertFileContent "home-files/${settingsPath}" "${expectedSettings}"
  '';
}
