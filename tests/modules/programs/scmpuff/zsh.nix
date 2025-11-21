{
  programs = {
    scmpuff.enable = true;
    zsh.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'eval "$(@scmpuff@/bin/scmpuff init --shell=zsh)"'
  '';
}
