{ config, ... }: {
  services.swww = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@swww@"; };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/swww.service
    assertFileContent $serviceFile ${./swww-graphical-session-target.service}
  '';
}
