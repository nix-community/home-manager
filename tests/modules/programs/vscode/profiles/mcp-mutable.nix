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

  inherit (helpers)
    mcpJsonPath
    settingsJsonPath
    tasksJsonPath
    userDirectory
    ;

  # when multiple profiles are defined, they are immutable by default.
  # but we can override this to force the profiles mutable instead.
  #
  forkConfig = forkInputs // {
    mutableProfile = true;

    profiles = {
      default.mcp = mcpJsonPath;
      default.settings = settingsJsonPath;

      work.mcp = mcpJsonPath;
      work.tasks = tasksJsonPath;
    };
  };

  mcpDirectory = if packageName == "code-cursor" then ".cursor" else userDirectory;
in
{
  config = lib.setAttrByPath [ "programs" package.pname ] forkConfig // {
    nmt.script = ''
      echo "pname: ${package.pname}, packageName: ${packageName}"
      echo "mcpDirectory: ${mcpDirectory}"
      echo "userDirectory: ${userDirectory}"

      # default profile: all files
      #
      assertFileExists "home-files/${mcpDirectory}/.immutable-mcp.json"
      assertFileContent "home-files/${mcpDirectory}/.immutable-mcp.json" "${mcpJsonPath}"
      assertPathNotExists "home-files/${mcpDirectory}/mcp.json" # mutable copy is created only during activation

      assertFileExists "home-files/${userDirectory}/.immutable-settings.json"
      assertFileContent "home-files/${userDirectory}/.immutable-settings.json" "${settingsJsonPath}"
      assertPathNotExists "home-files/${userDirectory}/settings.json" # mutable copy is created only during activation

      # work profile: skip mcp files only
      #
      ${
        if packageName == "code-cursor" then
          ''
            assertPathNotExists "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json" # immutable copy is created only during activation
            assertPathNotExists "home-files/${mcpDirectory}/profiles/work/mcp.json" # mutable copy is created only during activation
          ''
        else
          ''
            assertFileExists "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json"
            assertFileContent "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json" "${mcpJsonPath}"
            assertPathNotExists "home-files/${mcpDirectory}/profiles/work/mcp.json" # mutable copy is created only during activation
          ''
      }

      assertFileExists "home-files/${userDirectory}/profiles/work/.immutable-tasks.json"
      assertFileContent "home-files/${userDirectory}/profiles/work/.immutable-tasks.json" "${tasksJsonPath}"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/tasks.json" # mutable copy is created only during activation
    '';
  };
}
