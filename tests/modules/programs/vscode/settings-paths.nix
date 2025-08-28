{
  modulePath,
  packageName,
  configDirName,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  config =
    { }
    // lib.setAttrByPath modulePath ({
      enable = true;

      package = config.lib.test.mkStubPackage {
        name = packageName;
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
    })
    // {
      nmt.script =
        let
          settingsFilePath =
            profileName:
            lib.concatStringsSep "/" [
              (
                if pkgs.stdenv.hostPlatform.isDarwin then
                  "Library/Application Support/${configDirName}/User"
                else
                  ".config/${configDirName}/User"
              )
              (lib.optionalString (profileName != "default") "profiles/${profileName}")
              "settings.json"
            ];
        in
        ''
          assertFileExists "home-files/${settingsFilePath "default"}"
          assertFileExists "home-files/${settingsFilePath "work"}"
        '';
    };
}
