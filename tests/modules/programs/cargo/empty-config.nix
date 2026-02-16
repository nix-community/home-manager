{
  programs.cargo = {
    settings = {
      net = {
        git-fetch-with-cli = true;
      };
    };
  };

  nmt.script = ''
    assertPathNotExists home-files/.cargo/config
    assertPathNotExists home-files/.cargo/config.toml
  '';
}
