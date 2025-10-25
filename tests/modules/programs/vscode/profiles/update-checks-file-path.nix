{ forkInputs, lib, ... }@inputs:
let
  inherit (import ../test-helpers.nix inputs)
    isMutableProfile
    settingsJsonObject
    settingsJsonPath
    userDirectory
    vscodePackageName
    ;

  forkConfig = forkInputs // {
    profiles = {
      default = {
        # we can't modify a path file, so the update checks don't apply to this profile
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
in
{
  config = lib.setAttrByPath [ "programs" vscodePackageName ] forkConfig // {
    nmt.script = ''
      # mutable profiles create immutable nix store files and mutable copies on activation
      # immutable profiles create immutable nix store files linked to the files themselves
      #
      if [[ -n "${toString isMutableProfile}" ]]; then
        assertLinkExists "home-files/${userDirectory}/.immutable-settings.json"
        assertFileExists "home-files/${userDirectory}/.immutable-settings.json"
        assertFileContent "home-files/${userDirectory}/.immutable-settings.json" "${settingsJsonPath}"

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
        assertFileContent "home-files/${userDirectory}/settings.json" "${settingsJsonPath}"

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
