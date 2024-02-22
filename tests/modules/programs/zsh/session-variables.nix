{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.zsh = {
      enable = true;

      sessionVariables = {
        V1 = "v1";
        V2 = "v2-${config.programs.zsh.sessionVariables.V1}";
        EDITOR = ''emacsclient -t -a ""'';
      };
    };

    test.stubs.zsh = { };

    nmt.script = ''
      assertFileExists home-files/.zshenv
      assertFileRegex home-files/.zshenv 'export V1="v1"'
      assertFileRegex home-files/.zshenv 'export V2="v2-v1"'
      assertFileRegex home-files/.zshenv 'export EDITOR="emacsclient -t -a \\"\\""'
    '';
  };
}
