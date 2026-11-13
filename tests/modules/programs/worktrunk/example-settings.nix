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
    assertFileContent \
      home-files/.config/worktrunk/config.toml \
      ${builtins.toFile "worktrunk-config.toml" ''
        skip-shell-integration-prompt = true

        [post-start]
        copy = "wt step copy-ignored"
      ''}
  '';
}
