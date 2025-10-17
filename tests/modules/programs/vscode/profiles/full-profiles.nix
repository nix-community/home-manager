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
    keybindingsJsonPath
    keybindingsJsonObject
    mcpJsonObject
    mcpJsonPath
    settingsJsonPath
    settingsJsonObject
    tasksJsonObject
    tasksJsonPath
    userDirectory
    ;

  forkConfig = {
    inherit (forkInputs) package packageName;

    enable = true;

    # when multiple profiles are defined, they are immutable by default.
    #
    profiles = {
      default = {
        keybindings = keybindingsJsonPath;
        mcp = mcpJsonObject;
        settings = settingsJsonPath;
        tasks = tasksJsonObject;
      };

      work = {
        keybindings = keybindingsJsonObject;
        mcp = mcpJsonPath;
        settings = settingsJsonObject;
        tasks = tasksJsonPath;
      };
    };
  };

  mcpDirectory = if packageName == "code-cursor" then ".cursor" else userDirectory;
in
{
  config = lib.setAttrByPath [ "programs" package.pname ] forkConfig // {
    nmt.script = ''
      echo "pname: ${package.pname}, packageName: ${packageName}"
      echo "userDirectory: ${userDirectory}"
      echo "mcpDirectory: ${mcpDirectory}"

      # default profile: all files
      #
      assertFileExists "home-files/${mcpDirectory}/mcp.json"
      assertFileExists "home-files/${userDirectory}/keybindings.json"
      assertFileExists "home-files/${userDirectory}/settings.json"
      assertFileExists "home-files/${userDirectory}/tasks.json"

      assertFileContent "home-files/${mcpDirectory}/mcp.json" "${mcpJsonPath}"
      assertFileContent "home-files/${userDirectory}/keybindings.json" "${keybindingsJsonPath}"
      assertFileContent "home-files/${userDirectory}/settings.json" "${settingsJsonPath}"
      assertFileContent "home-files/${userDirectory}/tasks.json" "${tasksJsonPath}"

      assertPathNotExists "home-files/${mcpDirectory}/.immutable-mcp.json"
      assertPathNotExists "home-files/${userDirectory}/.immutable-keybindings.json"
      assertPathNotExists "home-files/${userDirectory}/.immutable-settings.json"
      assertPathNotExists "home-files/${userDirectory}/.immutable-tasks.json"

      # work profile: all files, except cursor mcp file
      #
      assertFileExists "home-files/${userDirectory}/profiles/work/keybindings.json"
      assertFileExists "home-files/${userDirectory}/profiles/work/settings.json"
      assertFileExists "home-files/${userDirectory}/profiles/work/tasks.json"

      assertFileContent "home-files/${userDirectory}/profiles/work/keybindings.json" "${keybindingsJsonPath}"
      assertFileContent "home-files/${userDirectory}/profiles/work/settings.json" "${settingsJsonPath}"
      assertFileContent "home-files/${userDirectory}/profiles/work/tasks.json" "${tasksJsonPath}"

      assertPathNotExists "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-keybindings.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-settings.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-tasks.json"

      ${
        if packageName == "code-cursor" then
          ''assertPathNotExists "home-files/${mcpDirectory}/profiles/work/mcp.json"''
        else
          ''assertFileContent "home-files/${mcpDirectory}/profiles/work/mcp.json" "${mcpJsonPath}"''
      }
    '';
  };
}
