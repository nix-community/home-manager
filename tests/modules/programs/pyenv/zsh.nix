{
  programs = {
    zsh.enable = true;
    pyenv.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'eval "$(@pyenv@/bin/pyenv init - zsh)"'
  '';
}
