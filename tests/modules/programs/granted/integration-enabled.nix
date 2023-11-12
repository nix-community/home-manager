{ pkgs, ... }:

{
  programs = {
    granted.enable = true;
    zsh.enable = true;
  };

  test.stubs.granted = { };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'function assume()'
    assertFileContains \
      home-files/.zshrc \
      'export GRANTED_ALIAS_CONFIGURED="true"'
    assertFileContains \
      home-files/.zshrc \
      'source @granted@/bin/.assume-wrapped "$@"'
    assertFileContains \
      home-files/.zshrc \
      'unset GRANTED_ALIAS_CONFIGURED'
  '';
}
