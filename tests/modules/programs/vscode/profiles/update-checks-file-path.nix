{ forkInputs, lib, ... }@inputs:
let
  inherit (import ../test-helpers.nix inputs)
    isMutableProfile
    settingsJsonObject
    settingsJsonPath
    userDirectory
    ;

  forkConfig = forkInputs // {
    profiles = {
      default = {
        # we don't add update checks to other profiles, so we use a file path to test the update checks are merged correctly
        settings = settingsJsonPath;

        enableUpdateCheck = false;
        enableExtensionUpdateCheck = false;
      };

      work = {
        settings = settingsJsonObject;

        enableUpdateCheck = false;
        enableExtensionUpdateCheck = false;
      };
    };
  };

  updateChecksSettingsJsonPath = builtins.toFile "${forkInputs.package.pname}-update-checks-settings.json.test" ''
    {
      "extensions.autoCheckUpdates": false,
      "files.autoSave": "on",
      "update.mode": "none"
    }
  '';
in
{
  config = lib.setAttrByPath [ "programs" forkInputs.moduleName ] forkConfig // {
    test.asserts.warnings.expected = [
      "programs.${forkInputs.moduleName}.profiles.*.enableUpdateCheck and programs.${forkInputs.moduleName}.profiles.*.enableExtensionUpdateCheck only have effect for the default profile."
    ];

    nmt.script = ''
      if [[ -n "${toString isMutableProfile}" ]]; then
        # default profile applies update checks
        #
        assertLinkExists "home-files/${userDirectory}/.immutable-settings.json"
        assertFileExists "home-files/${userDirectory}/.immutable-settings.json"
        assertFileContent "home-files/${userDirectory}/.immutable-settings.json" "${updateChecksSettingsJsonPath}"

        # other profiles don't apply update checks
        #
        assertLinkExists "home-files/${userDirectory}/profiles/work/.immutable-settings.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/.immutable-settings.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/.immutable-settings.json" "${settingsJsonPath}"

        # mutable copies are created only during activation
        #
        assertPathNotExists "home-files/${userDirectory}/settings.json"
        assertPathNotExists "home-files/${userDirectory}/profiles/work/settings.json"
      else
        # default profile applies update checks
        #
        assertLinkExists "home-files/${userDirectory}/settings.json"
        assertFileExists "home-files/${userDirectory}/settings.json"
        assertFileContent "home-files/${userDirectory}/settings.json" "${updateChecksSettingsJsonPath}"

        # other profiles don't apply update checks
        #
        assertLinkExists "home-files/${userDirectory}/profiles/work/settings.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/settings.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/settings.json" "${settingsJsonPath}"

        # the immutable links are not created because the files are immutable by default
        #
        assertPathNotExists "home-files/${userDirectory}/.immutable-settings.json"
        assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-settings.json"
      fi;
    '';
  };
}
