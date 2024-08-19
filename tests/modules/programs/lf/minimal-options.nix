{ config, lib, ... }:

with lib;

let expected = builtins.toFile "settings-expected" "\n\n\n\n\n\n\n\n\n\n\n";
in {
  config = {
    programs.lf = { enable = true; };

    test.stubs.lf = { };

    nmt.script = ''
      assertFileExists home-files/.config/lf/lfrc
      assertFileContent home-files/.config/lf/lfrc ${expected}
    '';
  };
}
