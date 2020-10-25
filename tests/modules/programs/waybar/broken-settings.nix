{ config, lib, pkgs, ... }:

with lib;

let
  package = pkgs.writeScriptBin "dummy-waybar" "" // { outPath = "@waybar@"; };
  expected = pkgs.writeText "expected-json" ''
    [
      {
        "height": 26,
        "layer": "top",
        "modules-center": [
          "sway/window"
        ],
        "modules-left": [
          "sway/workspaces",
          "sway/mode"
        ],
        "modules-right": [
          "idle_inhibitor",
          "pulseaudio",
          "network",
          "cpu",
          "memory",
          "backlight",
          "tray",
          "clock"
        ],
        "output": [
          "DP-1",
          "eDP-1",
          "HEADLESS-1"
        ],
        "position": "top",
        "sway/workspaces": {
          "all-outputs": true
        }
      }
    ]
  '';
in {
  config = {
    programs.waybar = {
      inherit package;
      enable = true;
      systemd.enable = true;
      settings = [{
        layer = "top";
        position = "top";
        height = 26;
        output = [ "DP-1" "eDP-1" "HEADLESS-1" ];
        modules-left = [ "sway/workspaces" "sway/mode" ];
        modules-center = [ "sway/window" ];
        modules-right = [
          "idle_inhibitor"
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "backlight"
          "tray"
          "clock"
        ];

        modules = { "sway/workspaces".all-outputs = true; };
      }];
    };

    nmt.description = ''
      Test for the broken configuration
      https://github.com/nix-community/home-manager/pull/1329#issuecomment-653253069
    '';
    nmt.script = ''
      assertPathNotExists home-files/.config/waybar/style.css
      assertFileContent \
        home-files/.config/waybar/config \
        ${expected}
    '';
  };
}
