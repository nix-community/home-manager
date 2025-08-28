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
        default.keybindings = [
          {
            key = "ctrl+c";
            command = "editor.action.clipboardCopyAction";
            when = "textInputFocus";
          }
        ];
        work.keybindings = [
          {
            key = "ctrl+c";
            command = "editor.action.clipboardCopyAction";
            when = "textInputFocus";
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
          assertFileExists "home-files/${profilePath "default" "keybindings.json"}"
          assertPathNotExists "home-files/${profilePath "default" ".immutable-keybindings.json"}"

          assertFileExists "home-files/${profilePath "work" "keybindings.json"}"
          assertPathNotExists "home-files/${profilePath "work" ".immutable-keybindings.json"}"
        '';
    };
}
