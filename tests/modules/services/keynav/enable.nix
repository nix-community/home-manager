{ config, ... }:

{
  services.keynav = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "keynav";
      outPath = "@keynav@";
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/keynav.service
    assertFileExists $serviceFile
    assertFileContent $serviceFile ${./enable-expected.service}
    assertPathNotExists home-files/.keynavrc
  '';
}
