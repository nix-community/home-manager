{
  programs.bash.enable = true;
  programs.goto.enable = true;
  programs.zsh.enable = true;

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileRegex home-files/.bashrc '^source \S*/share/goto.sh$'
    assertFileExists home-files/.zshrc
    assertFileRegex home-files/.zshrc '^source \S*/share/goto.sh$'
  '';
}
