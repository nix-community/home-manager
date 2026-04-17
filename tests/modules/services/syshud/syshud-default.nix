{ config, ... }:
{
  services.syshud = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "syshud";
      outPath = "@syshud@";
    };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/sys64/hud/style.css
    assertPathNotExists home-files/.config/sys64/hud/config.conf

    serviceFile=home-files/.config/systemd/user/syshud.service
    assertFileContent $serviceFile ${./syshud-default.service}
  '';
}
