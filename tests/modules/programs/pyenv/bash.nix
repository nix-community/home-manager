{
  programs = {
    bash.enable = true;
    pyenv.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'eval "$(@pyenv@/bin/pyenv init - bash)"'
  '';
}
