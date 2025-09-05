{
  programs.sherlock = {
    enable = true;
    settings = {
      theme = "dark";
      width = 500;
      max_results = 8;
    };
  };

  nmt.script =
    let
      configFile = "home-files/.config/sherlock/config.toml";
    in
    ''
      assertFileExists "${configFile}"
      assertFileContent "${configFile}" ${./basic-configuration.toml}
    '';
}
