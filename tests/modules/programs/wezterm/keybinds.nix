{ config, lib, pkgs, ... }:
with lib; {
  config = {
    programs.wezterm = {
      enable = true;

      keybindings = [
        { key = "l"; }
        {
          modifiers = [ ];
          key = "l";
          action = "wezterm.action {ActivateTabRelative = 1}";
        }
        {
          modifiers = [ "SHIFT" "CTRL" ];
          key = "h";
          action = "wezterm.action {ActivateTabRelative = -1}";
        }
      ];
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/wezterm/wezterm.lua \
        ${./keybinds-expected.lua}
    '';
  };
}
