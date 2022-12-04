{ config, lib, pkgs, ... }:

with lib;

let conf = builtins.toFile "settings-expected" "";
in {
  config = {
    programs.calcurse = { enable = true; };

    test.stubs.calcurse = { };

    nmt.script = ''
      assertFileExists home-files/.config/calcurse/conf
      assertFileContent home-files/.config/calcurse/conf ${conf}
    '';
  };
}
