{ forkInputs, lib, ... }@inputs:
let
  inherit (import ../test-helpers.nix inputs)
    tasksJsonPath
    userDirectory
    isMutableProfile
    ;

  forkConfig = forkInputs // {
    profiles = {
      default.tasks = tasksJsonPath;
      work.tasks = tasksJsonPath;
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
        assertLinkExists "home-files/${userDirectory}/.immutable-tasks.json"
        assertFileExists "home-files/${userDirectory}/.immutable-tasks.json"
        assertFileContent "home-files/${userDirectory}/.immutable-tasks.json" "${tasksJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/.immutable-tasks.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/.immutable-tasks.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/.immutable-tasks.json" "${tasksJsonPath}"

        # mutable copies are created only during activation
        #
        assertPathNotExists "home-files/${userDirectory}/tasks.json"
        assertPathNotExists "home-files/${userDirectory}/profiles/work/tasks.json"
      else
        assertLinkExists "home-files/${userDirectory}/tasks.json"
        assertFileExists "home-files/${userDirectory}/tasks.json"
        assertFileContent "home-files/${userDirectory}/tasks.json" "${tasksJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/tasks.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/tasks.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/tasks.json" "${tasksJsonPath}"

        # the immutable links are not created because the files are immutable by default
        #
        assertPathNotExists "home-files/${userDirectory}/.immutable-tasks.json"
        assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-tasks.json"
      fi;
    '';
  };
}
