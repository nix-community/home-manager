{
  programs = {
    granted.enable = true;
    zsh.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'function assume()'
    assertFileContains \
      home-files/.zshrc \
      'export GRANTED_ALIAS_CONFIGURED="true"'
    assertFileRegex \
      home-files/.zshrc \
      'source /nix/store/.*granted.*/bin/assume "$@"'
    assertFileContains \
      home-files/.zshrc \
      'unset GRANTED_ALIAS_CONFIGURED'
  '';
}
