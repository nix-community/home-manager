{
  programs.cargo = {
    enable = true;

    cargoHome = ".config/cargo";

    settings = {
      net = {
        git-fetch-with-cli = true;
      };
    };
  };

  nmt.script =
    let
      cargoTestPath = "home-files/.config/cargo";
      configTestPath = "${cargoTestPath}/config.toml";
    in
    ''
      assertPathNotExists home-files/.cargo/config
      assertDirectoryExists ${cargoTestPath}
      assertFileExists ${configTestPath}
      assertFileContent ${configTestPath} \
        ${./example-config.toml}
    '';
}
