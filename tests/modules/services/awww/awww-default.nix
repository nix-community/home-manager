{ config, ... }:
{
  services.awww = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "awww";
      outPath = "@awww@";
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/awww.service
    assertFileExists $serviceFile
    assertFileContent $serviceFile ${./awww-default.service}
  '';
}
