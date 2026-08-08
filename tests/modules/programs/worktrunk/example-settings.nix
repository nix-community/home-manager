{
  programs.worktrunk = {
    enable = true;
    settings = {
      skip-shell-integration-prompt = true;
      post-start = {
        copy = "wt step copy-ignored";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/worktrunk/config.toml
    assertFileContains \
      home-files/.config/worktrunk/config.toml \
      'skip-shell-integration-prompt = true'
    assertFileContains \
      home-files/.config/worktrunk/config.toml \
      '[post-start]'
    assertFileContains \
      home-files/.config/worktrunk/config.toml \
      'copy = "wt step copy-ignored"'
  '';
}
