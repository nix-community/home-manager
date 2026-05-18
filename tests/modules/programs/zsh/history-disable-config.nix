{
  programs.zsh = {
    enable = true;
    history.enableConfig = false;
  };

  nmt.script = ''
    assertFileNotRegex home-files/.zshrc "setopt HIST_.*"
  '';
}
