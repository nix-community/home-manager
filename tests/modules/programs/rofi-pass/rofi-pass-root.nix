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

    nixpkgs.overlays = [
      (self: super:
        let dummy = pkgs.writeScriptBin "dummy" "";
        in {
          rofi = dummy;
          rofi-pass = dummy;
        })
    ];

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
