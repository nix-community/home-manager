{ ... }:

{
  imports = [ ./zsh-stubs.nix ];

  config = {
    programs.zsh = {
      enable = true;
      historySubstringSearch = {
        enable = true;
        searchDownKey = "^[[B";
        searchUpKey = [ "^[[A" "\\eOA" ];
      };
    };

    # Written with regex to ensure we don't end up missing newlines in the future
    nmt.script = ''
      assertFileRegex home-files/.zshrc "^bindkey \"\^\[\[B\" history-substring-search-down$"
      assertFileRegex home-files/.zshrc "^bindkey \"\^\[\[A\" history-substring-search-up$"
      assertFileRegex home-files/.zshrc "^bindkey \"\\\\eOA\" history-substring-search-up$"
    '';
  };
}
