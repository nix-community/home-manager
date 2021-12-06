{ config, lib, pkgs, ... }:

with lib;

{
  programs.less = {
    enable = true;

    keys = ''
      s        back-line
      t        forw-line
    '';
  };

  test.stubs.less = { };

  nmt.script = ''
    assertFileExists home-files/.config/lesskey
    assertFileContent home-files/.config/lesskey ${
      builtins.toFile "less.expected" ''
        s        back-line
        t        forw-line
      ''
    }
  '';
}
