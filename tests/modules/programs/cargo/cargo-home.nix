{
  config,
  ...
}:

{
  programs.cargo = {
    enable = true;

    cargoHome = "${config.xdg.dataHome}/cargo";

    settings = {
      net = {
        git-fetch-with-cli = true;
      };
    };
  };

  nmt.script =
    let
      cargoTestPath = "home-files/.local/share/cargo";
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
