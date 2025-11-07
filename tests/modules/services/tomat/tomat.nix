{
  services.tomat = {
    enable = true;

    settings = {
      timer = {
        break = 10;
        work = 60;
      };
    };
  };

  nmt.script =
    let
      serviceFile = "home-files/.config/systemd/user/tomat.service";
      configFile = "home-files/.config/tomat/config.toml";
    in
    ''
      assertFileExists "${serviceFile}"
      assertFileExists "${configFile}"

      assertFileContent "${serviceFile}" ${./expected.service}
      assertFileContent "${configFile}" ${./expected-config.toml}
    '';
}
