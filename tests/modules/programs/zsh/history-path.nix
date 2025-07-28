case:
{ config, lib, ... }:

let
  homeDir = config.home.homeDirectory;

  histfileName = ".zsh_history";

  customHistRelPath = "some/subdir/${histfileName}";
  customHistAbsPath = "${homeDir}/${customHistRelPath}";

  # default option isn't exposed by submodule so this won't reflect
  # changes to the the module and may need to be updated in future
  defaultHistPath = "${homeDir}/${histfileName}";

  testPath =
    if case == "absolute" then
      customHistAbsPath
    else if case == "relative" then
      customHistRelPath
    else if case == "default" then
      defaultHistPath
    else if case == "xdg-variable" then
      "\${XDG_STATE_HOME:-\$HOME/.local/state}/zsh/history"
    else if case == "zdotdir-variable" then
      "\$ZDOTDIR/.zsh_history"
    else
      abort "Test condition not provided";

  expectedPath =
    if case == "default" then
      defaultHistPath
    else if case == "xdg-variable" then
      "\${XDG_STATE_HOME:-\$HOME/.local/state}/zsh/history"
    else if case == "zdotdir-variable" then
      "\$ZDOTDIR/.zsh_history"
    else
      customHistAbsPath;
in
{
  config = {
    programs.zsh = {
      enable = true;
      history.path = testPath;
      dotDir = lib.mkIf (case == "zdotdir-variable") "${homeDir}/.config/zsh";
    };

    test.stubs.zsh = { };

    nmt.script =
      if case == "xdg-variable" then
        ''
          assertFileContains home-files/.zshrc 'HISTFILE="''${XDG_STATE_HOME:-''$HOME/.local/state}/zsh/history"'
        ''
      else if case == "zdotdir-variable" then
        ''
          assertFileContains home-files/.config/zsh/.zshrc 'HISTFILE="$ZDOTDIR/.zsh_history"'
          assertFileContains home-files/.config/zsh/.zshenv "export ZDOTDIR=${homeDir}/.config/zsh"
        ''
      else
        ''
          assertFileRegex home-files/.zshrc '^HISTFILE="${expectedPath}"$'
        '';
  };
}
