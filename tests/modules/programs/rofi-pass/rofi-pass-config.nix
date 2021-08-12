{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.rofi = {
      enable = true;

      pass = {
        enable = true;
        extraConfig = ''
          # Extra config for rofi-pass
          xdotool_delay=12
        '';
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
            # Extra config for rofi-pass
            xdotool_delay=12

          ''
        }
    '';
  };
}
