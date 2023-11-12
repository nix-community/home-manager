{ ... }:

{
  programs = {
    bash.enable = true;
    pyenv.enable = true;
  };

  test.stubs.pyenv = { name = "pyenv"; };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'eval "$(@pyenv@/bin/pyenv init - bash)"'
  '';
}
