{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.rofi = {
      enable = true;

      pass = {
        enable = true;
        stores = [ "~/.local/share/password-store" ];
      };
    };

    test.stubs = {
      rofi = { };
      rofi-pass = { };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/rofi-pass/config \
        ${
          pkgs.writeText "rofi-pass-expected-config" ''
            root=~/.local/share/password-store
          ''
        }
    '';
  };
}
