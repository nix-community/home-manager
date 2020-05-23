{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.i3status = {
      enable = true;
      enableDefault = false;

      general = {
        colors = true;
        color_good = "#e0e0e0";
        color_degraded = "#d7ae00";
        color_bad = "#f69d6a";
        interval = 1;
      };

      modules = {
        "volume master" = {
          position = 1;
          settings = {
            format = "♪ %volume";
            format_muted = "♪ muted (%volume)";
            device = "pulse:1";
          };
        };
        "disk /" = {
          position = 2;
          settings = { format = "/ %avail"; };
        };
      };
    };

    nixpkgs.overlays = [
      (self: super: { i3status = pkgs.writeScriptBin "dummy-i3status" ""; })
    ];

    nmt.script = ''
      assertFileContent \
        $home_files/.config/i3status/config \
        ${
          pkgs.writeText "i3status-expected-config" ''
            general {
              color_bad = "#f69d6a"
              color_degraded = "#d7ae00"
              color_good = "#e0e0e0"
              colors = true
              interval = 1
            }

            order += "volume master"
            order += "disk /"
            disk / {
              format = "/ %avail"
            }

            volume master {
              device = "pulse:1"
              format = "♪ %volume"
              format_muted = "♪ muted (%volume)"
            }
          ''
        }
    '';
  };
}
