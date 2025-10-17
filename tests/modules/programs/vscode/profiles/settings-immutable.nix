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

  inherit (helpers) settingsJsonPath userDirectory;

  forkConfig = {
    inherit (forkInputs) package packageName;

    enable = true;

    # when multiple profiles are defined, they are immutable by default.
    #
    profiles = {
      default.settings = settingsJsonPath;
      work.settings = settingsJsonPath;
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
      assertFileExists "home-files/${userDirectory}/settings.json"
      assertFileContent "home-files/${userDirectory}/settings.json" "${settingsJsonPath}"
      assertPathNotExists "home-files/${userDirectory}/.immutable-settings.json"

      # work profile: all files
      #
      assertFileExists "home-files/${userDirectory}/profiles/work/settings.json"
      assertFileContent "home-files/${userDirectory}/profiles/work/settings.json" "${settingsJsonPath}"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-settings.json"
    '';
  };
}
