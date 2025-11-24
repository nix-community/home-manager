{
  services.gotify-desktop = {
    enable = true;
    url = "wss://foo.bar";
    token = "secret-token";
    extraConfig = {
      foo.bar = "extra";
    };
  };

  nmt.script = ''
    servicePath=home-files/.config/systemd/user
    configPath=home-files/.config/gotify-desktop

    assertFileExists $servicePath/gotify-desktop.service
    assertFileExists $configPath/config.toml

    assertFileContent $configPath/config.toml ${./config-extra-config.toml}
  '';
}
