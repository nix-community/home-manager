{
  programs.cargo = {
    enable = true;

    settings = {
      net = {
        git-fetch-with-cli = true;
      };
    };
  };

  nmt.script =
    let
      configTestPath = "home-files/.cargo/config.toml";
    in
    ''
      assertPathNotExists home-files/.cargo/config
      assertFileExists ${configTestPath}
      assertFileContent ${configTestPath} \
        ${./example-config.toml}
    '';
}
