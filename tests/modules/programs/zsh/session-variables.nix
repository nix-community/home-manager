{ config, lib, ... }:

{
  programs.zsh = {
    enable = true;

    sessionVariables = {
      PATH = "$HOME/bin:$PATH";
      V1 = "v1";
      V2 = "v2-${config.programs.zsh.sessionVariables.V1}";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.zshenv
    assertFileContent home-files/.zshenv ${./session-variables.zshenv}
  '';
}
