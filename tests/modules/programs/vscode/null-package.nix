{
  pkgs,
  ...
}:

let
  settingsPath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/Code/User/settings.json"
    else
      ".config/Code/User/settings.json";

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
    profiles.default.userSettings."editor.fontSize" = 14;
  };

  nmt.script = ''
    assertFileExists "home-files/${settingsPath}"
    assertFileContent "home-files/${settingsPath}" "${expectedSettings}"
  '';
}
