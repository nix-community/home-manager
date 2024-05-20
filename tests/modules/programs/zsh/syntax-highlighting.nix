{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.zsh = {
      enable = true;
      syntaxHighlighting = {
        enable = true;
        package = pkgs.hello;
        highlighters = [ "brackets" "pattern" "cursor" ];
        styles.comment = "fg=#6c6c6c";
        patterns."rm -rf *" = "fg=white,bold,bg=red";
      };
    };

    test.stubs.zsh = { };

    nmt.script = ''
      assertFileContains home-files/.zshrc "source ${pkgs.hello}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
      assertFileContains home-files/.zshrc "ZSH_HIGHLIGHT_HIGHLIGHTERS+=('brackets' 'pattern' 'cursor')"
      assertFileContains home-files/.zshrc "ZSH_HIGHLIGHT_STYLES+=('comment' 'fg=#6c6c6c')"
    '';
  };
}
