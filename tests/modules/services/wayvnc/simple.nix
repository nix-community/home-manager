{ config, ... }:
{
  services.wayvnc = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    autoStart = true;

    settings = {
      address = "0.0.0.0";
      port = 5901;
      username = "foobar";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/wayvnc.service
    assertFileContent \
      $(normalizeStorePaths home-files/.config/systemd/user/wayvnc.service) \
      ${./simple.service}

    assertFileExists home-files/.config/wayvnc/config
    assertFileContent home-files/.config/wayvnc/config ${./simple-config}
  '';

}
