{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.zsh = {
      enable = true;
      historySubstringSearch = {
        enable = true;
        searchDownKey = "^[[B";
        searchUpKey = [ "^[[A" "\\eOA" ];
        prefixed = true;
      };
    };

    test.stubs.zsh = { };

    # Written with regex to ensure we don't end up missing newlines in the future
    nmt.script = ''
      assertFileRegex home-files/.zshrc "^bindkey '\^\[\[B' history-substring-search-down$"
      assertFileRegex home-files/.zshrc "^bindkey '\^\[\[A' history-substring-search-up$"
      assertFileRegex home-files/.zshrc "^bindkey '\\\\eOA' history-substring-search-up$"
      assertFileRegex home-files/.zshrc "^HISTORY_SUBSTRING_SEARCH_PREFIXED=true$"
    '';
  };
}
