{ config, lib, pkgs, ... }:
with lib; {
  config = {
    programs.wezterm = {
      enable = true;

      keybindings = [
        {
          modifiers = [ ];
          key = "l";
        }
        {
          key = "l";
          action = "wezterm.action {ActivateTabRelative = 1}";
        }
        {
          modifiers = [ "SHIFT" "CTRL" ];
          key = "h";
          action = "wezterm.action {ActivateTabRelative = -1}";
        }
      ];

      mousebindings = [
        {
          button = "Left";
          event = "Up";
          count = 1;
          modifiers = [ "CTRL" ];
          action = ''"OpenLinkAtMouseCursor"'';
        }
        {
          button = "Right";
          event = "Down";
          count = 1;
          action = ''wezterm.action { SendString = "woot" }'';
        }
      ];

      config = {
        enable_wayland = true;
        font_size = 10.0;
        line_height = 1.0;
      };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/wezterm/wezterm.lua \
        ${./everything-expected.lua}
    '';
  };
}
