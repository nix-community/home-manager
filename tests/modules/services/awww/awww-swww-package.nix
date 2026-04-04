{ config, ... }:
{
  services.awww = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "swww";
      outPath = "@swww@";
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/awww.service
    assertFileContains $serviceFile "ExecStart=@swww@/bin/swww-daemon"
  '';
}
