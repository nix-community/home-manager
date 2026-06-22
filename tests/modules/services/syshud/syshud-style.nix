{
  config,
  ...
}:
{
  services.syshud = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "syshud";
      outPath = "@syshud@";
    };
    style = ''
      * {
        background-color: red;
      }
    '';
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/sys64/hud/config.conf

    serviceFile=home-files/.config/systemd/user/syshud.service
    assertFileExists $serviceFile
    assertFileContent $serviceFile ${./syshud-default.service}

    styleFile=home-files/.config/sys64/hud/style.css
    assertFileExists $styleFile
    assertFileContent $styleFile ${./syshud-style.css}
  '';
}
