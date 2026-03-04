let
  cargo_home = ".cargo_home";
in
{
  programs.cargo = {
    enable = true;

    home = cargo_home;

    settings = {
      net = {
        git-fetch-with-cli = true;
      };
    };
  };

  nmt.script =
    let
      configTestPath = "home-files/${cargo_home}/config.toml";
    in
    ''
      assertPathNotExists home-files/${cargo_home}/config
      assertFileExists ${configTestPath}
    '';
}
