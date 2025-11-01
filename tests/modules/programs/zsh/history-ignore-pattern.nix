{
  programs.zsh = {
    enable = true;
    history.ignorePatterns = [
      "echo *"
      "rm *"
    ];
  };

  nmt.script = ''
    assertFileContains home-files/.zshrc "HISTORY_IGNORE='(echo *|rm *)'"
  '';
}
