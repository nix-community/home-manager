{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.waybar = {
      package = config.lib.test.mkStubPackage { outPath = "@waybar@"; };
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
          "battery#bat1"
          "battery#bat2"
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
                config.lib.test.mkStubPackage { outPath = "@dummy@"; };
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
