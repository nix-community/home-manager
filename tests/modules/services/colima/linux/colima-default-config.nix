{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.colima = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "colima";
      outPath = "@colima@";
    };
    dockerPackage = config.lib.test.mkStubPackage {
      name = "docker";
      outPath = "@docker@";
    };
    perlPackage = config.lib.test.mkStubPackage {
      name = "perl";
      outPath = "@perl@";
    };
    sshPackage = config.lib.test.mkStubPackage {
      name = "openssh";
      outPath = "@openssh@";
    };
    coreutilsPackage = config.lib.test.mkStubPackage {
      name = "coreutils";
      outPath = "@coreutils@";
    };
    curlPackage = config.lib.test.mkStubPackage {
      name = "curl";
      outPath = "@curl@";
    };
    bashPackage = config.lib.test.mkStubPackage {
      name = "bashNonInteractive";
      outPath = "@bashNonInteractive@";
    };
  };

  nmt.script = ''
    assertPathNotExists home-files/.colima/default/colima.yaml

    assertFileExists home-files/.config/systemd/user/colima-default.service

    assertFileContent \
      home-files/.config/systemd/user/colima-default.service \
      ${./expected-service.service}
  '';
}
