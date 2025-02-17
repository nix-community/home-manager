{ config, ... }:

{
  services.volnoti = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "volnoti";
      outPath = "@volnoti@";
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/volnoti.service
    assertFileExists $serviceFile
    assertFileContent $serviceFile \
      ${
        builtins.toFile "expected-volnoti.service" ''
          [Install]
          WantedBy=graphical-session.target

          [Service]
          ExecStart=@volnoti@/bin/volnoti -v -n

          [Unit]
          Description=volnoti
        ''
      }
  '';
}
