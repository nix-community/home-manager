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

  inherit (helpers) tasksJsonPath userDirectory;

  forkConfig = {
    inherit (forkInputs) package packageName;

    enable = true;

    # when multiple profiles are defined, they are immutable by default.
    #
    profiles = {
      default.tasks = tasksJsonPath;
      work.tasks = tasksJsonPath;
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
      assertFileExists "home-files/${userDirectory}/tasks.json"
      assertFileContent "home-files/${userDirectory}/tasks.json" "${tasksJsonPath}"
      assertPathNotExists "home-files/${userDirectory}/.immutable-tasks.json"

      # work profile: all files
      #
      assertFileExists "home-files/${userDirectory}/profiles/work/tasks.json"
      assertFileContent "home-files/${userDirectory}/profiles/work/tasks.json" "${tasksJsonPath}"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-tasks.json"
    '';
  };
}
