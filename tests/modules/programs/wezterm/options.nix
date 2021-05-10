{ config, lib, pkgs, ... }:
with lib; {
  config = {
    programs.wezterm = {
      enable = true;

      config = {
        font_size = 0.0;
        font_sharper = "Harfbuzz";
      };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/wezterm/wezterm.lua \
        ${./options-expected.lua}
    '';
  };
}
