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

    profiles.default.settings = {
      cpu = 4;
      memory = 8;
      kubernetes.enabled = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.colima/default/colima.yaml
    assertFileContent home-files/.colima/default/colima.yaml ${./custom-settings-expected.yaml}
  '';
}
