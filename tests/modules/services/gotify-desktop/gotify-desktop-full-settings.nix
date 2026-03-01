{
  services.gotify-desktop = {
    enable = true;

    settings = {
      gotify = {
        url = "wss://foo.bar";
        token.command = "secret-token-command";
      };

      foo.bar = "foobar";
    };
  };

  nmt.script = ''
    servicePath=home-files/.config/systemd/user
    configPath=home-files/.config/gotify-desktop

    assertFileExists $servicePath/gotify-desktop.service
    assertFileExists $configPath/config.toml

    assertFileContent $configPath/config.toml ${./config-full-settings.toml}
  '';
}
