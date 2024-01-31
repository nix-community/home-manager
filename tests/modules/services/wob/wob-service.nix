{ config, ... }:

{
  services.wob = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "wob";
      outPath = "@wob@";
    };
    systemd = true;

    settings."".background_color = "ddddddff";
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/wob.service
    socketFile=home-files/.config/systemd/user/wob.socket
    configFile=home-files/.config/wob/wob.ini

    assertFileExists $serviceFile
    assertFileExists $socketFile
    assertFileExists $configFile
    assertFileContent $(normalizeStorePaths $serviceFile) ${
      ./wob-service-expected.service
    }
    assertFileContent $socketFile ${./wob-service-expected.socket}
    assertFileContent $configFile ${./wob-service-expected.ini}
  '';
}
