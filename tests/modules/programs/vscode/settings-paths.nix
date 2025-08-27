{ pkgs, lib, ... }:

let
  settingsFilePath =
    name:
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/Cursor/User/${
        lib.optionalString (name != "default") "profiles/${name}/"
      }settings.json"
    else
      ".config/Cursor/User/${lib.optionalString (name != "default") "profiles/${name}/"}settings.json";
in
{
  programs.cursor = {
    enable = true;

    package = pkgs.writeScriptBin "code-cursor" "" // {
      pname = "code-cursor";
      version = "1.75.0";
    };

    profiles = {
      default.settings = {
        "files.autoSave" = "off";
      };
      work.settings = {
        "editor.tabSize" = 4;
      };
    };
  };

  nmt.script = ''
    assertFileExists "home-files/${settingsFilePath "default"}"
    assertFileExists "home-files/${settingsFilePath "work"}"
  '';
}
