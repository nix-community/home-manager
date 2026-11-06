{
  services.gotify-desktop.enable = true;

  nmt.script = ''
    servicePath=home-files/.config/systemd/user
    configPath=home-files/.config/gotify-desktop

    assertFileExists $servicePath/gotify-desktop.service
    assertPathNotExists $configPath/config.toml
  '';
}
