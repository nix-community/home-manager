{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.i3status = {
      enable = true;
      enableDefault = true;
    };

    nixpkgs.overlays = [
      (self: super: { i3status = pkgs.writeScriptBin "dummy-i3status" ""; })
    ];

    nmt.script = ''
      assertFileContent \
        home-files/.config/i3status/config \
        ${
          pkgs.writeText "i3status-expected-config" ''
            general {
              colors = true
              interval = 5
            }

            order += "ipv6"
            order += "wireless _first_"
            order += "ethernet _first_"
            order += "battery all"
            order += "disk /"
            order += "load"
            order += "memory"
            order += "tztime local"
            battery all {
              format = "%status %percentage %remaining"
            }

            disk / {
              format = "%avail"
            }

            ethernet _first_ {
              format_down = "E: down"
              format_up = "E: %ip (%speed)"
            }

            ipv6 {
              
            }

            load {
              format = "%1min"
            }

            memory {
              format = "%used | %available"
              format_degraded = "MEMORY < %available"
              threshold_degraded = "1G"
            }

            tztime local {
              format = "%Y-%m-%d %H:%M:%S"
            }

            wireless _first_ {
              format_down = "W: down"
              format_up = "W: (%quality at %essid) %ip"
            }
          ''
        }
    '';
  };
}
