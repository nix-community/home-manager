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

      # when multiple profiles are defined, the profiles are immutable by default.
      # this ensures that the profiles are not modified by mistake, so the files
      # are read-only because of the nix store.
      #
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
          profilePath =
            profileName: fileName:
            lib.concatStringsSep "/" [
              (
                if pkgs.stdenv.hostPlatform.isDarwin then
                  "Library/Application Support/${configDirName}/User"
                else
                  ".config/${configDirName}/User"
              )
              (lib.optionalString (profileName != "default") "profiles/${profileName}")
              fileName
            ];
        in
        ''
          assertFileExists "home-files/${profilePath "default" "settings.json"}"
          assertPathNotExists "home-files/${profilePath "default" ".immutable-settings.json"}"

          assertFileExists "home-files/${profilePath "work" "settings.json"}"
          assertPathNotExists "home-files/${profilePath "work" ".immutable-settings.json"}"
        '';
    };
}
