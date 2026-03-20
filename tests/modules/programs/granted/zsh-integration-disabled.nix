{
  programs = {
    granted.enable = true;
    granted.enableZshIntegration = false;
    zsh.enable = true;
  };

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
      'source @granted@/bin/assume "$@"'
    assertFileNotRegex \
      home-files/.zshrc \
      'unset GRANTED_ALIAS_CONFIGURED'
  '';
}
