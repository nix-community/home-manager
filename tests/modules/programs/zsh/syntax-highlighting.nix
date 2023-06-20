{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.zsh = {
      enable = true;
      syntaxHighlighting = {
        enable = true;
        styles.comment = "fg=#6c6c6c";
      };
    };

    test.stubs.zsh = { };

    nmt.script = ''
      assertFileContains home-files/.zshrc "source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
      assertFileContains home-files/.zshrc "ZSH_HIGHLIGHT_STYLES['comment']='fg=#6c6c6c'"
    '';
  };
}
