{
  services.gotify-desktop = {
    enable = true;

    settings.gotify.url = "wss://foo.bar";
  };

  nmt.script = ''
    servicePath=home-files/.config/systemd/user
    configPath=home-files/.config/gotify-desktop

    assertFileExists $servicePath/gotify-desktop.service
    assertFileExists $configPath/config.toml

    assertFileContent $configPath/config.toml ${./config-url.toml}
  '';
}
