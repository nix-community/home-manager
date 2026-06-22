{
  programs.feedr = {
    enable = true;
    settings = {
      network.http_timeout = 15;
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/feedr/config.toml"
    assertFileContent "home-files/.config/feedr/config.toml" \
      ${builtins.toFile "feedr-expected.toml" ''
        [network]
        http_timeout = 15
      ''}
  '';
}
