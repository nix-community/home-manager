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
      (self: super: { rofi-pass = pkgs.writeScriptBin "dummy-rofi-pass" ""; })
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
