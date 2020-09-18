{ config, lib, pkgs, ... }:

with lib;

let
  package = pkgs.writeScriptBin "dummy-waybar" "" // { outPath = "@waybar@"; };
in {
  config = {
    programs.waybar = {
      inherit package;
      enable = true;
      settings = [{
        layer = "top";
        position = "top";
        height = 30;
        output = [ "DP-1" ];
        modules-left = [ "sway/workspaces" "sway/mode" "custom/my-module" ];
        modules-center = [ "sway/window" ];
        modules-right = [
          "idle_inhibitor"
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "backlight"
          "tray"
          "battery"
          "clock"
        ];

        modules = {
          "sway/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
          };
          "sway/mode" = { tooltip = false; };
          "sway/window" = { max-length = 120; };
          "idle_inhibitor" = { format = "{icon}"; };
          "custom/my-module" = {
            format = "hello from {}";
            exec = let
              dummyScript =
                pkgs.writeShellScriptBin "dummy" "echo within waybar" // {
                  outPath = "@dummy@";
                };
            in "${dummyScript}/bin/dummy";
          };
        };
      }];
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/waybar/style.css
      assertFileContent \
        home-files/.config/waybar/config \
        ${./settings-complex-expected.json}
    '';
  };
}
