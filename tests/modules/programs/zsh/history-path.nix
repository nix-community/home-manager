case:
{ config, lib, ... }:

with lib;
let
  homeDir = config.home.homeDirectory;

  histfileName = ".zsh_history";

  customHistRelPath = "some/subdir/${histfileName}";
  customHistAbsPath = "${homeDir}/${customHistRelPath}";

  # default option isn't exposed by submodule so this won't reflect
  # changes to the the module and may need to be updated in future
  defaultHistPath = "${homeDir}/${histfileName}";

  testPath = if case == "absolute" then
    customHistAbsPath
  else if case == "relative" then
    customHistRelPath
  else if case == "default" then
    defaultHistPath
  else
    abort "Test condition not provided";

  expectedPath =
    if case == "default" then defaultHistPath else customHistAbsPath;
in {
  config = {
    programs.zsh = {
      enable = true;
      history.path = testPath;
    };

    test.stubs.zsh = { };

    nmt.script = ''
      assertFileRegex home-files/.zshrc '^HISTFILE="${expectedPath}"$'
    '';
  };
}
