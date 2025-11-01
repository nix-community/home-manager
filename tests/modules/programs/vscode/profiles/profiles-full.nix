{ forkInputs, lib, ... }@inputs:
let
  helpers = import ../test-helpers.nix inputs;

  inherit (helpers)
    elixirSnippetsJsonPath
    elixirSnippetsObject
    globalSnippetsJsonPath
    globalSnippetsObject
    haskellSnippetsJsonPath
    haskellSnippetsObject
    isMutableProfile
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
    profiles = {
      default = {
        keybindings = keybindingsJsonPath;
        mcp = mcpJsonObject;
        settings = settingsJsonPath;
        tasks = tasksJsonObject;

        snippets = {
          global = globalSnippetsJsonPath;

          languages = {
            elixir = elixirSnippetsJsonPath;
            haskell = haskellSnippetsJsonPath;
          };
        };
      };

      work = {
        keybindings = keybindingsJsonObject;
        mcp = mcpJsonPath;
        settings = settingsJsonObject;
        tasks = tasksJsonPath;

        snippets = {
          global = globalSnippetsObject;

          languages = {
            elixir = elixirSnippetsObject;
            haskell = haskellSnippetsObject;
          };
        };
      };
    };
  };

  mcpDirectory = if forkInputs.package.pname == "cursor" then ".cursor" else userDirectory;
in
{
  config = lib.setAttrByPath [ "programs" forkInputs.moduleName ] forkConfig // {
    nmt.script = ''
      # mutable profiles create immutable nix store files and mutable copies on activation
      # immutable profiles create immutable nix store files linked to the files themselves
      #
      if [[ -n "${toString isMutableProfile}" ]]; then
        # Keybindings
        #
        assertLinkExists "home-files/${userDirectory}/.immutable-keybindings.json"
        assertFileExists "home-files/${userDirectory}/.immutable-keybindings.json"
        assertFileContent "home-files/${userDirectory}/.immutable-keybindings.json" "${keybindingsJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/.immutable-keybindings.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/.immutable-keybindings.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/.immutable-keybindings.json" "${keybindingsJsonPath}"

        # MCP
        #
        assertLinkExists "home-files/${mcpDirectory}/.immutable-mcp.json"
        assertFileExists "home-files/${mcpDirectory}/.immutable-mcp.json"
        assertFileContent "home-files/${mcpDirectory}/.immutable-mcp.json" "${mcpJsonPath}"

        if [[ "${forkInputs.package.pname}" == "cursor" ]]; then
          assertPathNotExists "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json"
        else
          assertLinkExists "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json"
          assertFileExists "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json"
          assertFileContent "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json" "${mcpJsonPath}"
        fi

        # Settings
        #
        assertLinkExists "home-files/${userDirectory}/.immutable-settings.json"
        assertFileExists "home-files/${userDirectory}/.immutable-settings.json"
        assertFileContent "home-files/${userDirectory}/.immutable-settings.json" "${settingsJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/.immutable-settings.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/.immutable-settings.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/.immutable-settings.json" "${settingsJsonPath}"

        # Snippets: global
        #
        assertLinkExists "home-files/${userDirectory}/snippets/.immutable-global.code-snippets"
        assertFileExists "home-files/${userDirectory}/snippets/.immutable-global.code-snippets"
        assertFileContent "home-files/${userDirectory}/snippets/.immutable-global.code-snippets" "${globalSnippetsJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-global.code-snippets"
        assertFileExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-global.code-snippets"
        assertFileContent "home-files/${userDirectory}/profiles/work/snippets/.immutable-global.code-snippets" "${globalSnippetsJsonPath}"

        # Snippets: elixir
        #
        assertLinkExists "home-files/${userDirectory}/snippets/.immutable-elixir.json"
        assertFileExists "home-files/${userDirectory}/snippets/.immutable-elixir.json"
        assertFileContent "home-files/${userDirectory}/snippets/.immutable-elixir.json" "${elixirSnippetsJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-elixir.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-elixir.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/snippets/.immutable-elixir.json" "${elixirSnippetsJsonPath}"

        # Snippets: haskell
        #
        assertLinkExists "home-files/${userDirectory}/snippets/.immutable-haskell.json"
        assertFileExists "home-files/${userDirectory}/snippets/.immutable-haskell.json"
        assertFileContent "home-files/${userDirectory}/snippets/.immutable-haskell.json" "${haskellSnippetsJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-haskell.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-haskell.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/snippets/.immutable-haskell.json" "${haskellSnippetsJsonPath}"

        # Tasks
        #
        assertLinkExists "home-files/${userDirectory}/.immutable-tasks.json"
        assertFileExists "home-files/${userDirectory}/.immutable-tasks.json"
        assertFileContent "home-files/${userDirectory}/.immutable-tasks.json" "${tasksJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/.immutable-tasks.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/.immutable-tasks.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/.immutable-tasks.json" "${tasksJsonPath}"

        # mutable copies are created only during activation
        #
        assertPathNotExists "home-files/${mcpDirectory}/profiles/work/mcp.json"

        assertPathNotExists "home-files/${userDirectory}/keybindings.json"
        assertPathNotExists "home-files/${userDirectory}/profiles/work/keybindings.json"

        assertPathNotExists "home-files/${userDirectory}/settings.json"
        assertPathNotExists "home-files/${userDirectory}/profiles/work/settings.json"

        assertPathNotExists "home-files/${userDirectory}/tasks.json"
        assertPathNotExists "home-files/${userDirectory}/profiles/work/tasks.json"
      else
        # Keybindings
        #
        assertLinkExists "home-files/${userDirectory}/keybindings.json"
        assertFileExists "home-files/${userDirectory}/keybindings.json"
        assertFileContent "home-files/${userDirectory}/keybindings.json" "${keybindingsJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/keybindings.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/keybindings.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/keybindings.json" "${keybindingsJsonPath}"

        # MCP
        #
        assertLinkExists "home-files/${mcpDirectory}/mcp.json"
        assertFileExists "home-files/${mcpDirectory}/mcp.json"
        assertFileContent "home-files/${mcpDirectory}/mcp.json" "${mcpJsonPath}"

        if [[ "${forkInputs.package.pname}" == "cursor" ]]; then
          assertPathNotExists "home-files/${mcpDirectory}/profiles/work/mcp.json"
        else
          assertLinkExists "home-files/${mcpDirectory}/profiles/work/mcp.json"
          assertFileExists "home-files/${mcpDirectory}/profiles/work/mcp.json"
          assertFileContent "home-files/${mcpDirectory}/profiles/work/mcp.json" "${mcpJsonPath}"
        fi

        # Tasks
        #
        assertLinkExists "home-files/${userDirectory}/tasks.json"
        assertFileExists "home-files/${userDirectory}/tasks.json"
        assertFileContent "home-files/${userDirectory}/tasks.json" "${tasksJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/tasks.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/tasks.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/tasks.json" "${tasksJsonPath}"

        # Settings
        #
        assertLinkExists "home-files/${userDirectory}/settings.json"
        assertFileExists "home-files/${userDirectory}/settings.json"
        assertFileContent "home-files/${userDirectory}/settings.json" "${settingsJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/settings.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/settings.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/settings.json" "${settingsJsonPath}"

        # Snippets: global
        #
        assertLinkExists "home-files/${userDirectory}/snippets/global.code-snippets"
        assertFileExists "home-files/${userDirectory}/snippets/global.code-snippets"
        assertFileContent "home-files/${userDirectory}/snippets/global.code-snippets" "${globalSnippetsJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/snippets/global.code-snippets"
        assertFileExists "home-files/${userDirectory}/profiles/work/snippets/global.code-snippets"
        assertFileContent "home-files/${userDirectory}/profiles/work/snippets/global.code-snippets" "${globalSnippetsJsonPath}"

        # Snippets: elixir
        #
        assertLinkExists "home-files/${userDirectory}/snippets/elixir.json"
        assertFileExists "home-files/${userDirectory}/snippets/elixir.json"
        assertFileContent "home-files/${userDirectory}/snippets/elixir.json" "${elixirSnippetsJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/snippets/elixir.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/snippets/elixir.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/snippets/elixir.json" "${elixirSnippetsJsonPath}"

        # Haskell Snippets
        #
        assertLinkExists "home-files/${userDirectory}/snippets/haskell.json"
        assertFileExists "home-files/${userDirectory}/snippets/haskell.json"
        assertFileContent "home-files/${userDirectory}/snippets/haskell.json" "${haskellSnippetsJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/snippets/haskell.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/snippets/haskell.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/snippets/haskell.json" "${haskellSnippetsJsonPath}"

        # the immutable links are not created because the files are immutable by default
        #
        assertPathNotExists "home-files/${mcpDirectory}/.immutable-mcp.json"
        assertPathNotExists "home-files/${userDirectory}/.immutable-tasks.json"
        assertPathNotExists "home-files/${userDirectory}/.immutable-settings.json"
        assertPathNotExists "home-files/${userDirectory}/.immutable-keybindings.json"

        assertPathNotExists "home-files/${userDirectory}/snippets/.immutable-global.code-snippets"
        assertPathNotExists "home-files/${userDirectory}/snippets/.immutable-elixir.json"
        assertPathNotExists "home-files/${userDirectory}/snippets/.immutable-haskell.json"
      fi;
    '';
  };
}
