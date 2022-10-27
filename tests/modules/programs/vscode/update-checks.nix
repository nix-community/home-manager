{ pkgs, ... }:

let

  settingsPath = if pkgs.stdenv.hostPlatform.isDarwin then
    "Library/Application Support/Code/User/settings.json"
  else
    ".config/Code/User/settings.json";

  expectedSettings = pkgs.writeText "settings-expected.json" ''
    {
      "extensions.autoCheckUpdates": false,
      "update.mode": "none"
    }
  '';

in {
  programs.vscode = {
    enable = true;
    package = pkgs.writeScriptBin "vscode" "" // { pname = "vscode"; };
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
  };

  nmt.script = ''
    assertFileExists "home-files/${settingsPath}"
    assertFileContent "home-files/${settingsPath}" "${expectedSettings}"
  '';
}
