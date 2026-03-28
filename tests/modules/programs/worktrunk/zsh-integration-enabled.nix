{ pkgs, ... }:

{
  programs = {
    worktrunk.enable = true;
    worktrunk.enableZshIntegration = true;
    zsh.enable = true;
  };

  test.stubs.granted = { };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'eval "$(@worktrunk@/bin/wt config shell init zsh)"'
  '';
}
