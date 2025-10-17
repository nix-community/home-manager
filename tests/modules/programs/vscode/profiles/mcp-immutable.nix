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
  #
  forkConfig = forkInputs // {
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
      assertFileExists "home-files/${mcpDirectory}/mcp.json"
      assertFileExists "home-files/${userDirectory}/settings.json"

      assertFileContent "home-files/${mcpDirectory}/mcp.json" "${mcpJsonPath}"
      assertFileContent "home-files/${userDirectory}/settings.json" "${settingsJsonPath}"

      assertPathNotExists "home-files/${mcpDirectory}/.immutable-mcp.json"
      assertPathNotExists "home-files/${userDirectory}/.immutable-settings.json"

      # work profile: skip mcp files
      #
      ${
        if packageName == "code-cursor" then
          ''
            assertPathNotExists "home-files/${mcpDirectory}/profiles/work/mcp.json"
            assertPathNotExists "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json"
          ''
        else
          ''
            assertFileExists "home-files/${mcpDirectory}/profiles/work/mcp.json"
            assertFileContent "home-files/${mcpDirectory}/profiles/work/mcp.json" "${mcpJsonPath}"
            assertPathNotExists "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json"
          ''
      }

      assertFileExists "home-files/${userDirectory}/profiles/work/tasks.json"
      assertFileContent "home-files/${userDirectory}/profiles/work/tasks.json" "${tasksJsonPath}"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-tasks.json"
    '';
  };
}
