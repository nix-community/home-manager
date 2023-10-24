{ pkgs, ... }:

{
  programs = {
    granted.enable = true;
    granted.enableZshIntegration = false;
    zsh.enable = true;
  };

  test.stubs.granted = { };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileNotRegex \
      home-files/.zshrc \
      'function assume()'
    assertFileNotRegex \
      home-files/.zshrc \
      'export GRANTED_ALIAS_CONFIGURED="true"'
    assertFileNotRegex \
      home-files/.zshrc \
      'source @granted@/bin/.assume-wrapped "$@"'
    assertFileNotRegex \
      home-files/.zshrc \
      'unset GRANTED_ALIAS_CONFIGURED'
  '';
}
