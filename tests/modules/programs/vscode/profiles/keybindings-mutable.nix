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

  # when multiple profiles are defined, they are immutable by default.
  # however we can override this to make the profiles mutable
  #
  forkConfig = forkInputs // {
    mutableProfile = true;

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
      assertFileExists "home-files/${userDirectory}/.immutable-tasks.json"
      assertFileContent "home-files/${userDirectory}/.immutable-tasks.json" "${tasksJsonPath}"
      assertPathNotExists "home-files/${userDirectory}/tasks.json" # mutable copy is created only during activation

      # work profile: all files
      #
      assertFileExists "home-files/${userDirectory}/profiles/work/.immutable-tasks.json"
      assertFileContent "home-files/${userDirectory}/profiles/work/.immutable-tasks.json" "${tasksJsonPath}"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/tasks.json" # mutable copy is created only during activation
    '';
  };
}
