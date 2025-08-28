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

      # when only default profile is defined, default profile is mutable by default
      # this ensures that the profile can be modified by the user and the files are
      # regenerated when the profile is changed.
      #
      profiles = {
        default.tasks = [
          {
            type = "shell";
            label = "Hello task";
            command = "hello";
          }
        ];
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
          assertFileExists "home-files/${profilePath "default" ".immutable-tasks.json"}"
          assertPathNotExists "home-files/${profilePath "default" "tasks.json"}"
        '';
    };
}
