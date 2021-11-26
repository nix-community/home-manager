{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.less = {
      enable = true;

      keys = ''
        s        back-line
        t        forw-line
      '';
    };

    nmt.script = ''
      assertFileExists home-files/.lesskey
      assertFileContent home-files/.lesskey ${
        pkgs.writeText "less.expected" ''
          s        back-line
          t        forw-line
        ''
      }
    '';
  };
}
