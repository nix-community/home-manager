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
      # mutable profiles create immutable nix store files and mutable copies on activation
      # immutable profiles create immutable nix store files linked to the files themselves
      #
      if [[ -n "${toString isMutableProfile}" ]]; then
        assertLinkExists "home-files/${userDirectory}/.immutable-settings.json"
        assertFileExists "home-files/${userDirectory}/.immutable-settings.json"
        assertFileContent "home-files/${userDirectory}/.immutable-settings.json" "${updateChecksSettingsJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/.immutable-settings.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/.immutable-settings.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/.immutable-settings.json" "${settingsJsonPath}"

        # mutable copies are created only during activation
        #
        assertPathNotExists "home-files/${userDirectory}/settings.json"
        assertPathNotExists "home-files/${userDirectory}/profiles/work/settings.json"
      else
        assertLinkExists "home-files/${userDirectory}/settings.json"
        assertFileExists "home-files/${userDirectory}/settings.json"
        assertFileContent "home-files/${userDirectory}/settings.json" "${updateChecksSettingsJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/settings.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/settings.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/settings.json" "${settingsJsonPath}"

        # immutable links are not created
        #
        assertPathNotExists "home-files/${userDirectory}/.immutable-settings.json"
        assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-settings.json"
      fi;
    '';
  };
}
