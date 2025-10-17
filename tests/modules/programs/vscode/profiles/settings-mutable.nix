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

    # when multiple profiles are defined, they are immutable by default,
    # but we can force the profiles to be mutable instead.
    #
    mutableProfile = true;

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
      assertFileExists "home-files/${userDirectory}/.immutable-settings.json"
      assertFileContent "home-files/${userDirectory}/.immutable-settings.json" "${settingsJsonPath}"
      assertPathNotExists "home-files/${userDirectory}/settings.json" # mutable copy is created only during activation

      # work profile: all files
      #
      assertFileExists "home-files/${userDirectory}/profiles/work/.immutable-settings.json"
      assertFileContent "home-files/${userDirectory}/profiles/work/.immutable-settings.json" "${settingsJsonPath}"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/settings.json" # mutable copy is created only during activation
    '';
  };
}
