{
  programs = {
    granted.enable = true;
    bash.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'function assume()'
    assertFileContains \
      home-files/.bashrc \
      'export GRANTED_ALIAS_CONFIGURED="true"'
    assertFileContains \
      home-files/.bashrc \
      'source @granted@/bin/assume "$@"'
    assertFileContains \
      home-files/.bashrc \
      'unset GRANTED_ALIAS_CONFIGURED'
  '';
}
