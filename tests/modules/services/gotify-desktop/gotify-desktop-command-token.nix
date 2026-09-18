{
  services.gotify-desktop = {
    enable = true;

    settings.gotify.token.command = "secret-token-command";
  };

  nmt.script = ''
    servicePath=home-files/.config/systemd/user
    configPath=home-files/.config/gotify-desktop

    assertFileExists $servicePath/gotify-desktop.service
    assertFileExists $configPath/config.toml

    assertFileContent $configPath/config.toml ${./config-command-token.toml}
  '';
}
