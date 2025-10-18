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
    elixirSnippetsJsonPath
    elixirSnippetsObject
    globalSnippetsJsonPath
    globalSnippetsObject
    haskellSnippetsJsonPath
    haskellSnippetsObject
    keybindingsJsonObject
    keybindingsJsonPath
    mcpJsonObject
    mcpJsonPath
    settingsJsonObject
    settingsJsonPath
    tasksJsonObject
    tasksJsonPath
    userDirectory
    ;

  forkConfig = forkInputs // {
    # when multiple profiles are defined, they are immutable by default.
    #
    profiles = {
      default = {
        keybindings = keybindingsJsonPath;
        mcp = mcpJsonObject;
        settings = settingsJsonPath;
        tasks = tasksJsonObject;

        globalSnippets = globalSnippetsJsonPath;

        languageSnippets = {
          elixir = elixirSnippetsJsonPath;
          haskell = haskellSnippetsJsonPath;
        };
      };

      work = {
        keybindings = keybindingsJsonObject;
        mcp = mcpJsonPath;
        settings = settingsJsonObject;
        tasks = tasksJsonPath;

        globalSnippets = globalSnippetsObject;

        languageSnippets = {
          elixir = elixirSnippetsObject;
          haskell = haskellSnippetsObject;
        };
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

      # default profile: all settings and snippets
      #
      assertFileExists "home-files/${mcpDirectory}/mcp.json"
      assertFileExists "home-files/${userDirectory}/keybindings.json"
      assertFileExists "home-files/${userDirectory}/settings.json"
      assertFileExists "home-files/${userDirectory}/snippets/elixir.json"
      assertFileExists "home-files/${userDirectory}/snippets/global.code-snippets"
      assertFileExists "home-files/${userDirectory}/snippets/haskell.json"
      assertFileExists "home-files/${userDirectory}/tasks.json"

      assertFileContent "home-files/${mcpDirectory}/mcp.json" "${mcpJsonPath}"
      assertFileContent "home-files/${userDirectory}/keybindings.json" "${keybindingsJsonPath}"
      assertFileContent "home-files/${userDirectory}/settings.json" "${settingsJsonPath}"
      assertFileContent "home-files/${userDirectory}/tasks.json" "${tasksJsonPath}"
      assertFileContent "home-files/${userDirectory}/snippets/global.code-snippets" "${globalSnippetsJsonPath}"
      assertFileContent "home-files/${userDirectory}/snippets/elixir.json" "${elixirSnippetsJsonPath}"
      assertFileContent "home-files/${userDirectory}/snippets/haskell.json" "${haskellSnippetsJsonPath}"

      assertPathNotExists "home-files/${mcpDirectory}/.immutable-mcp.json"
      assertPathNotExists "home-files/${userDirectory}/.immutable-keybindings.json"
      assertPathNotExists "home-files/${userDirectory}/.immutable-settings.json"
      assertPathNotExists "home-files/${userDirectory}/.immutable-tasks.json"
      assertPathNotExists "home-files/${userDirectory}/snippets/.immutable-elixir.json"
      assertPathNotExists "home-files/${userDirectory}/snippets/.immutable-global.code-snippets"
      assertPathNotExists "home-files/${userDirectory}/snippets/.immutable-haskell.json"

      # work profile: all settings and snippets, except cursor mcp file
      #
      ${
        if packageName == "code-cursor" then
          ''
            assertPathNotExists "home-files/${mcpDirectory}/profiles/work/mcp.json"
          ''
        else
          ''
            assertFileExists "home-files/${mcpDirectory}/profiles/work/mcp.json"
            assertFileContent "home-files/${mcpDirectory}/profiles/work/mcp.json" "${mcpJsonPath}"
          ''
      }

      assertFileExists "home-files/${userDirectory}/profiles/work/keybindings.json"
      assertFileExists "home-files/${userDirectory}/profiles/work/settings.json"
      assertFileExists "home-files/${userDirectory}/profiles/work/tasks.json"
      assertFileExists "home-files/${userDirectory}/profiles/work/snippets/global.code-snippets"
      assertFileExists "home-files/${userDirectory}/profiles/work/snippets/elixir.json"
      assertFileExists "home-files/${userDirectory}/profiles/work/snippets/haskell.json"

      assertFileContent "home-files/${userDirectory}/profiles/work/keybindings.json" "${keybindingsJsonPath}"
      assertFileContent "home-files/${userDirectory}/profiles/work/settings.json" "${settingsJsonPath}"
      assertFileContent "home-files/${userDirectory}/profiles/work/tasks.json" "${tasksJsonPath}"
      assertFileContent "home-files/${userDirectory}/profiles/work/snippets/global.code-snippets" "${globalSnippetsJsonPath}"
      assertFileContent "home-files/${userDirectory}/profiles/work/snippets/elixir.json" "${elixirSnippetsJsonPath}"
      assertFileContent "home-files/${userDirectory}/profiles/work/snippets/haskell.json" "${haskellSnippetsJsonPath}"

      assertPathNotExists "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-keybindings.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-settings.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-tasks.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-elixir.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-global.code-snippets"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-haskell.json"
    '';
  };
}
