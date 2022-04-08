{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.wezterm = {
      enable = true;
      extraConfig = ''
        local wezterm = require 'wezterm';
        return {
          font = wezterm.font("JetBrains Mono"),
          font_size = 16.0,
          color_scheme = "Tomorrow Night",
          hide_tab_bar_if_only_one_tab = true,
          default_prog = { "zsh", "--login", "-c", "tmux attach -t dev || tmux new -s dev" },
          keys = {
            {key="n", mods="SHIFT|CTRL", action="ToggleFullScreen"},
          }
        }
      '';
    };

    test.stubs.wezterm = { };

    nmt.script = ''
      assertFileExists home-files/.config/wezterm/wezterm.lua
      assertFileContent home-files/.config/wezterm/wezterm.lua ${
        ./basic-config.lua
      }
    '';
  };
}
