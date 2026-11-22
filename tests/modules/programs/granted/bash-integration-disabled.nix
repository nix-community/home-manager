{
  programs = {
    granted.enable = true;
    granted.enableBashIntegration = false;
    bash.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileNotRegex \
      home-files/.bashrc \
      'function assume()'
    assertFileNotRegex \
      home-files/.bashrc \
      'export GRANTED_ALIAS_CONFIGURED="true"'
    assertFileNotRegex \
      home-files/.bashrc \
      'source @granted@/bin/assume "$@"'
    assertFileNotRegex \
      home-files/.bashrc \
      'unset GRANTED_ALIAS_CONFIGURED'
  '';
}
