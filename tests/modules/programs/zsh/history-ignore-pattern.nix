{
  imports = [
    ({ ... }: { config.programs.zsh.history.ignorePatterns = [ "echo *" ]; })
    ({ ... }: { config.programs.zsh.history.ignorePatterns = [ "rm *" ]; })
  ];

  programs.zsh.enable = true;

  nmt.script = ''
    assertFileContains home-files/.zshrc "HISTORY_IGNORE='(echo *|rm *)'"
  '';
}
