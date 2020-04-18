{ config, lib, pkgs, ... }:

with lib;

let expected = builtins.toFile "settings-expected" "\n\n\n\n\n\n\n\n\n\n\n";
in {
  config = {
    programs.lf = { enable = true; };

    nmt.script = ''
      assertFileExists home-files/.config/lf/lfrc
      assertFileContent home-files/.config/lf/lfrc ${expected}
    '';
  };
}
