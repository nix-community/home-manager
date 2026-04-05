{
  services.gotify-desktop = {
    enable = true;

    settings.gotify.token = "secret-token";
  };

  nmt.script = ''
    servicePath=home-files/.config/systemd/user
    configPath=home-files/.config/gotify-desktop

    assertFileExists $servicePath/gotify-desktop.service
    assertFileExists $configPath/config.toml

    assertFileContent $configPath/config.toml ${./config-str-token.toml}
  '';
}
