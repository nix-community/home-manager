{ ... }:

{
  programs = {
    fish.enable = true;
    pyenv.enable = true;
  };

  test.stubs.pyenv = { name = "pyenv"; };

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      '@pyenv@/bin/pyenv init - fish | source'
  '';
}
