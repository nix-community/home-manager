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
  helpers = import ../test-helpers.nix (forkInputs // inputs);

  inherit (helpers) keybindingsJsonPath userDirectory;

  forkConfig = {
    inherit (forkInputs) package packageName;

    enable = true;

    # when multiple profiles are defined, they are immutable by default.
    #
    profiles = {
      default.keybindings = keybindingsJsonPath;
      work.keybindings = keybindingsJsonPath;
    };
  };
in
{
  config = lib.setAttrByPath [ "programs" package.pname ] forkConfig // {
    nmt.script = ''
      echo "pname: ${package.pname}, packageName: ${packageName}"
      echo "userDirectory: ${userDirectory}"

      # default profile: all files
      #
      assertFileExists "home-files/${userDirectory}/keybindings.json"
      assertFileContent "home-files/${userDirectory}/keybindings.json" "${keybindingsJsonPath}"
      assertPathNotExists "home-files/${userDirectory}/.immutable-keybindings.json"

      # work profile: all files
      #
      assertFileExists "home-files/${userDirectory}/profiles/work/keybindings.json"
      assertFileContent "home-files/${userDirectory}/profiles/work/keybindings.json" "${keybindingsJsonPath}"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-keybindings.json"
    '';
  };
}
