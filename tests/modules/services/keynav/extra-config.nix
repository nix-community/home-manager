{ config, ... }:

{
  services.keynav = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "keynav";
      outPath = "@keynav@";
    };
    settings = {
      "2" = "doubleclick,end";
      "4" = "click 4";
      "5" = "click 5";
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/keynav.service
    assertFileExists $serviceFile
    assertFileContent $(normalizeStorePaths $serviceFile) ${./extra-config-expected.service}

    assertFileExists home-files/.config/keynav/keynavrc
    assertFileContent home-files/.config/keynav/keynavrc ${./extra-config-expected.keynavrc}
  '';
}
