{
  programs = {
    fish.enable = true;
    pyenv.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      '@pyenv@/bin/pyenv init - fish | source'
  '';
}
