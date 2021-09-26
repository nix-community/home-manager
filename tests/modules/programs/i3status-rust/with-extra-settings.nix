{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.i3status-rust = {
      enable = true;
      bars = {
        extra-settings = {
          blocks = [
            {
              block = "disk_space";
              path = "/";
              alias = "/";
              info_type = "available";
              unit = "GB";
              interval = 60;
              warning = 20.0;
              alert = 10.0;
            }
            {
              block = "memory";
              display_type = "memory";
              format_mem = "{Mug}GB ({Mup}%)";
              format_swap = "{SUp}%";
            }
            {
              block = "cpu";
              interval = 1;
              format = "{barchart}";
            }
            {
              block = "load";
              interval = 1;
              format = "{1m} {5m}";
            }
            {
              block = "temperature";
              collapsed = true;
              interval = 10;
              format = "{min}° min, {max}° max, {average}° avg";
              chip = "*-isa-*";
            }
            {
              block = "networkmanager";
              ap_format = "{ssid} @ {strength}%";
              on_click = "kcmshell5 kcm_networkmanagement";
            }
            {
              block = "net";
              device = "enp9s0u2u1u2c2";
              speed_up = true;
              interval = 5;
            }
            {
              block = "speedtest";
              bytes = true;
            }
            {
              block = "xrandr";
              interval =
                6000; # Because running the commands causes screen lag, see https://github.com/greshake/i3status-rust/issues/668
            }
            {
              block = "sound";
              format = "{output_name} {volume}%";
              on_click = "pavucontrol --tab=3";
              mappings = {
                "alsa_output.pci-0000_00_1f.3.analog-stereo" = "";
                "bluez_sink.70_26_05_DA_27_A4.a2dp_sink" = "";
              };
            }
            {
              block = "music";
              player = "spotify";
              buttons = [ "play" "prev" "next" ];
              on_collapsed_click = "i3-msg '[class=Spotify] focus'";
            }
            {
              block = "time";
              interval = 60;
              format = "%a %d.%m %R";
            }
            { block = "battery"; }
          ];

          icons = "awesome5";

          settings = {
            theme = {
              name = "solarized-dark";
              overrides = {
                idle_bg = "#123456";
                idle_fg = "#abcdef";
              };
            };
          };

          theme = "gruvbox-dark";
        };
      };
    };

    test.stubs.i3status-rust = { };

    nmt.script = ''
      assertFileExists home-files/.config/i3status-rust/config-extra-settings.toml 
      assertFileContent home-files/.config/i3status-rust/config-extra-settings.toml \
        ${
          pkgs.writeText "i3status-rust-expected-config" ''
            icons = "awesome5"
            [[block]]
            alert = 10
            alias = "/"
            block = "disk_space"
            info_type = "available"
            interval = 60
            path = "/"
            unit = "GB"
            warning = 20

            [[block]]
            block = "memory"
            display_type = "memory"
            format_mem = "{Mug}GB ({Mup}%)"
            format_swap = "{SUp}%"

            [[block]]
            block = "cpu"
            format = "{barchart}"
            interval = 1

            [[block]]
            block = "load"
            format = "{1m} {5m}"
            interval = 1

            [[block]]
            block = "temperature"
            chip = "*-isa-*"
            collapsed = true
            format = "{min}° min, {max}° max, {average}° avg"
            interval = 10

            [[block]]
            ap_format = "{ssid} @ {strength}%"
            block = "networkmanager"
            on_click = "kcmshell5 kcm_networkmanagement"

            [[block]]
            block = "net"
            device = "enp9s0u2u1u2c2"
            interval = 5
            speed_up = true

            [[block]]
            block = "speedtest"
            bytes = true

            [[block]]
            block = "xrandr"
            interval = 6000

            [[block]]
            block = "sound"
            format = "{output_name} {volume}%"
            on_click = "pavucontrol --tab=3"

            [block.mappings]
            "alsa_output.pci-0000_00_1f.3.analog-stereo" = ""
            "bluez_sink.70_26_05_DA_27_A4.a2dp_sink" = ""

            [[block]]
            block = "music"
            buttons = ["play", "prev", "next"]
            on_collapsed_click = "i3-msg '[class=Spotify] focus'"
            player = "spotify"

            [[block]]
            block = "time"
            format = "%a %d.%m %R"
            interval = 60

            [[block]]
            block = "battery"

            [theme]
            name = "solarized-dark"

            [theme.overrides]
            idle_bg = "#123456"
            idle_fg = "#abcdef"
                                              ''
        }
    '';
  };
}
