{
  package,
  packageName ? package.pname,
  ...
}@forkInputs:
{
  config,
  lib,
  pkgs,
  ...
}@inputs:
let
  inherit (import ../test-helpers.nix (forkInputs // inputs))
    settingsJsonObject
    settingsJsonPath
    userDirectory
    ;

  forkConfig = forkInputs // {
    profiles = {
      default = {
        settings = settingsJsonObject;

        enableUpdateCheck = false;
        enableExtensionUpdateCheck = false;
      };
      work = {
        settings = settingsJsonPath;

        enableUpdateCheck = false;
        enableExtensionUpdateCheck = false;
      };
    };
  };

  updateChecksSettingsJsonPath = builtins.toFile "${package.pname}-update-checks-settings.json.test" ''
    {
      "extensions.autoCheckUpdates": false,
      "files.autoSave": "on",
      "update.mode": "none"
    }
  '';
in
{
  config = lib.setAttrByPath [ "programs" package.pname ] forkConfig // {
    nmt.script = ''
      assertFileExists "home-files/${userDirectory}/settings.json"
      assertFileContent "home-files/${userDirectory}/settings.json" "${updateChecksSettingsJsonPath}"

      assertFileExists "home-files/${userDirectory}/profiles/work/settings.json"
      assertFileContent "home-files/${userDirectory}/profiles/work/settings.json" "${settingsJsonPath}"
    '';
  };
}
