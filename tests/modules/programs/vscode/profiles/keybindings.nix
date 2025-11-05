{ forkInputs, lib, ... }@inputs:
let
  inherit (import ../test-helpers.nix inputs)
    isMutableProfile
    keybindingsJsonObject
    keybindingsJsonPath
    userDirectory
    ;

  # when multiple profiles are defined, they are immutable by default.
  # however we can override this to make the profiles mutable
  #
  forkConfig = forkInputs // {
    profiles = {
      default.keybindings = keybindingsJsonPath;
      work.keybindings = keybindingsJsonObject;
    };
  };
in
{
  config = lib.setAttrByPath [ "programs" forkInputs.moduleName ] forkConfig // {
    nmt.script = ''
      # mutable profiles create immutable nix store files and mutable copies on activation
      # immutable profiles create immutable nix store files linked to the files themselves
      #
      if [[ -n "${toString isMutableProfile}" ]]; then
        assertLinkExists "home-files/${userDirectory}/.immutable-keybindings.json"
        assertFileExists "home-files/${userDirectory}/.immutable-keybindings.json"
        assertFileContent "home-files/${userDirectory}/.immutable-keybindings.json" "${keybindingsJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/.immutable-keybindings.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/.immutable-keybindings.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/.immutable-keybindings.json" "${keybindingsJsonPath}"

        # mutable copies are created only during activation
        #
        assertPathNotExists "home-files/${userDirectory}/keybindings.json"
        assertPathNotExists "home-files/${userDirectory}/profiles/work/keybindings.json"
      else
        assertLinkExists "home-files/${userDirectory}/keybindings.json"
        assertFileExists "home-files/${userDirectory}/keybindings.json"
        assertFileContent "home-files/${userDirectory}/keybindings.json" "${keybindingsJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/keybindings.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/keybindings.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/keybindings.json" "${keybindingsJsonPath}"

        # the immutable links are not created because the files are immutable by default
        #
        assertPathNotExists "home-files/${userDirectory}/.immutable-keybindings.json"
        assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-keybindings.json"
      fi;
    '';
  };
}
