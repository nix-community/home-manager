{ ... }:

{
  programs = {
    thefuck.enable = true;
    bash.enable = true;
    zsh.enable = true;
  };

  test.stubs.thefuck = { };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'eval "$(@thefuck@/bin/thefuck '"'"'--alias'"'"')"'

    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'eval "$(@thefuck@/bin/thefuck '"'"'--alias'"'"')"'
  '';
}
