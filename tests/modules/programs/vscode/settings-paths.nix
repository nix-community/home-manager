{ pkgs, lib, ... }:
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

  nmt.script =
    let
      settingsFilePath =
        profileName:
        lib.concatStringsSep "/" [
          (
            if pkgs.stdenv.hostPlatform.isDarwin then
              "Library/Application Support/Cursor/User"
            else
              ".config/Cursor/User"
          )
          (lib.optionalString (profileName != "default") "profiles/${profileName}")
          "settings.json"
        ];
    in
    ''
      assertFileExists "home-files/${settingsFilePath "default"}"
      assertFileExists "home-files/${settingsFilePath "work"}"
    '';
}
