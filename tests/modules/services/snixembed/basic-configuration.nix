{ config, ... }:

{
  services.snixembed = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "snixembed";
      outPath = "@custom-snixembed@";
    };
    beforeUnits = [ "safeeyes.service" ];
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/systemd/user/snixembed.service \
      ${./basic-configuration.service}
  '';
}
