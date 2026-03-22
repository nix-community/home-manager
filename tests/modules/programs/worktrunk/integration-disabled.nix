{ pkgs, ... }:

{
  programs = {
    worktrunk.enable = true;
    worktrunk.enableZshIntegration = false;
    zsh.enable = true;
  };

  test.stubs.worktrunk = { };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileNotRegex \
      home-files/.zshrc \
      'eval "$(@worktrunk@/bin/wt config shell init zsh)"'
  '';
}
