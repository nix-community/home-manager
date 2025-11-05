{
  forkInputs,
  lib,
  pkgs,
  ...
}@inputs:
let
  inherit (import ../test-helpers.nix inputs)
    globalSnippetsObject
    globalSnippetsJsonPath
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

  # api.v3: migrate top-level options to profiles.default
  #
  forkConfig = forkInputs // {
    mutableProfile = false;

    userSettings = settingsJsonObject;
    userTasks = tasksJsonObject;
    userMcp = mcpJsonObject;
    keybindings = keybindingsJsonObject;
    globalSnippets = globalSnippetsObject;
    languageSnippets = {
      haskell = haskellSnippetsObject;
    };
  };

  mcpPath = if forkInputs.package.pname == "cursor" then ".cursor" else userDirectory;
in
{
  config = lib.setAttrByPath [ "programs" forkInputs.moduleName ] forkConfig // {
    test.asserts.warnings.expected = [
      "The option `programs.${forkInputs.moduleName}.globalSnippets' defined in `<unknown-file>' has been renamed to `programs.${forkInputs.moduleName}.profiles.default.globalSnippets'."
      "The option `programs.${forkInputs.moduleName}.languageSnippets' defined in `<unknown-file>' has been renamed to `programs.${forkInputs.moduleName}.profiles.default.languageSnippets'."
      "The option `programs.${forkInputs.moduleName}.keybindings' defined in `<unknown-file>' has been renamed to `programs.${forkInputs.moduleName}.profiles.default.keybindings'."
      "The option `programs.${forkInputs.moduleName}.userMcp' defined in `<unknown-file>' has been renamed to `programs.${forkInputs.moduleName}.profiles.default.userMcp'."
      "The option `programs.${forkInputs.moduleName}.userTasks' defined in `<unknown-file>' has been renamed to `programs.${forkInputs.moduleName}.profiles.default.userTasks'."
      "The option `programs.${forkInputs.moduleName}.userSettings' defined in `<unknown-file>' has been renamed to `programs.${forkInputs.moduleName}.profiles.default.userSettings'."
    ];

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
