{
  programs.zsh = {
    enable = true;
    historySubstringSearch = {
      enable = true;
      searchDownKey = "^[[B";
      searchUpKey = [
        "^[[A"
        "\\eOA"
      ];
    };
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContent $(normalizeStorePaths home-files/.zshrc) ${./history-substring-search-expected.zshrc}
  '';
}
