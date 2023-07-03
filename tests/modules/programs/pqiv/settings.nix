{ config, ... }:

{
  programs.pqiv = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "pqiv"; };
    settings = {
      options = {
        hide-info-box = 1;
        thumbnail-size = "256x256";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/pqivrc
    assertFileContent home-files/.config/pqivrc ${
      builtins.toFile "pqiv.expected" ''
        [options]
        hide-info-box=1
        thumbnail-size=256x256
      ''
    }
  '';
}
