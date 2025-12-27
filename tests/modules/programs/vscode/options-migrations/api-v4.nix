{
  forkInputs,
  lib,
  pkgs,
  ...
}@inputs:
let
  inherit (import ../test-helpers.nix inputs)
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

  # api.v4: automatically migrates any obsolete profile options, no warnings are expected
  #
  forkConfig = forkInputs // {
    mutableProfile = false;

    profiles = {
      default = {
        userSettings = settingsJsonObject;
        userTasks = tasksJsonObject;
        userMcp = mcpJsonObject;
        keybindings = keybindingsJsonObject;
        globalSnippets = globalSnippetsObject;
        languageSnippets = {
          haskell = haskellSnippetsObject;
        };
      };
    };
  };

  mcpPath = if forkInputs.package.pname == "cursor" then ".cursor" else userDirectory;
in
{
  config = lib.setAttrByPath [ "programs" forkInputs.moduleName ] forkConfig // {
    test.asserts.warnings.expected = [ ];

    nmt.script = ''
      assertFileExists "home-files/${userDirectory}/keybindings.json"
      assertFileContent "home-files/${userDirectory}/keybindings.json" "${keybindingsJsonPath}"

      assertFileExists "home-files/${mcpPath}/mcp.json"
      assertFileContent "home-files/${mcpPath}/mcp.json" "${mcpJsonPath}"

      assertFileExists "home-files/${userDirectory}/settings.json"
      assertFileContent "home-files/${userDirectory}/settings.json" "${settingsJsonPath}"

      assertFileExists "home-files/${userDirectory}/tasks.json"
      assertFileContent "home-files/${userDirectory}/tasks.json" "${tasksJsonPath}"

      assertFileExists "home-files/${userDirectory}/snippets/global.code-snippets"
      assertFileContent "home-files/${userDirectory}/snippets/global.code-snippets" "${globalSnippetsJsonPath}"

      assertFileExists "home-files/${userDirectory}/snippets/haskell.json"
      assertFileContent "home-files/${userDirectory}/snippets/haskell.json" "${haskellSnippetsJsonPath}"
    '';
  };
}
