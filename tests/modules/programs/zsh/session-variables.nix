{ config, lib, ... }:

with lib;

{
  config = {
    programs.zsh = {
      enable = true;

      sessionVariables = {
        V1 = "v1";
        V2 = "v2-${config.programs.zsh.sessionVariables.V1}";
      };
    };

    nmt.script = ''
      assertFileExists home-files/.zshrc
      assertFileRegex home-files/.zshrc 'export V1="v1"'
      assertFileRegex home-files/.zshrc 'export V2="v2-v1"'
    '';
  };
}
