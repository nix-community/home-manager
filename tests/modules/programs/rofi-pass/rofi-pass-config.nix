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

    test.stubs = {
      rofi = { };
      rofi-pass = { };
    };

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
