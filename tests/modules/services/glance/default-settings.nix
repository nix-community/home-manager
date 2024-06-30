{ ... }:

{
  services.glance.enable = true;

  test.stubs.glance = { };

  nmt.script = ''
    configFile=home-files/.config/glance/glance.yml
    serviceFile=home-files/.config/systemd/user/glance.service

    assertFileContent $configFile ${./glance-default-config.yml}
    assertFileContent $serviceFile ${./glance.service}
  '';
}
