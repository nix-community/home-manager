package:

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
in

{
  programs.vscode = {
    enable = true;
    inherit package;
    profiles = {
      default = {
        userSettings = ./path-literal-settings.json;
        enableUpdateCheck = false;
        enableExtensionUpdateCheck = false;
      };
    };
  };

  nmt.script = ''
    assertFileExists "home-files/${settingsPath}"
    assertFileContent "home-files/${settingsPath}" "${./path-literal-settings.json}"
  '';
}
