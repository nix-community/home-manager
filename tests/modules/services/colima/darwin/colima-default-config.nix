{
  config,
  lib,
  pkgs,
  ...
}:

{
  nixpkgs.overlays = [
    (self: super: {
      darwin = super.darwin // {
        DarwinTools = config.lib.test.mkStubPackage {
          name = "DarwinTools";
          outPath = "@DarwinTools@";
        };
      };
    })
  ];

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

    serviceFile=LaunchAgents/org.nix-community.home.colima-default.plist

    assertFileExists "$serviceFile"

    assertFileContent "$serviceFile" ${./expected-agent.plist}
  '';
}
