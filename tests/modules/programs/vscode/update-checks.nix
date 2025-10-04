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

  settingsPath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/${cfg.nameShort}/User/settings.json"
    else
      ".config/${cfg.nameShort}/User/settings.json";

  expectedSettings = pkgs.writeText "settings-expected.json" ''
    {
      "extensions.autoCheckUpdates": false,
      "update.mode": "none"
    }
  '';
in

lib.mkIf (willUseIfd -> config.test.enableLegacyIfd) {
  programs.vscode = {
    enable = true;
    inherit package;
    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
    };
  };

  nmt.script = ''
    assertFileExists "home-files/${settingsPath}"
    assertFileContent "home-files/${settingsPath}" "${expectedSettings}"
  '';
}
