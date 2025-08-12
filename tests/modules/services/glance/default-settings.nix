{
  services.glance.enable = true;

  nmt.script = ''
    configFile=home-files/.config/glance/glance.yml
    serviceFile=home-files/.config/systemd/user/glance.service
    serviceFile=$(normalizeStorePaths $serviceFile)

    assertFileContent $configFile ${./glance-default-config.yml}
    assertFileContent $serviceFile ${./glance.service}
  '';
}
