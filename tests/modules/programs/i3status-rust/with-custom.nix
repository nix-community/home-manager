{ config, lib, pkgs, ... }:

{
  config = {
    programs.i3status-rust = {
      enable = true;
      bars = {
        custom = {
          blocks = [
            {
              block = "disk_space";
              path = "/";
              info_type = "available";
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
              format = " $icon $barchart ";
            }
            {
              block = "load";
              interval = 1;
              format = " $icon $1m $5m ";
            }
            {
              block = "temperature";
              interval = 10;
              format = "$icon $min min, $max max, $average avg";
              chip = "*-isa-*";
            }
            {
              block = "net";
              device = "enp9s0u2u1u2c2";
              interval = 5;
            }
            {
              block = "speedtest";
              format = " ^icon_ping $ping ";
            }
            {
              block = "xrandr";
              interval =
                6000; # Because running the commands causes screen lag, see https://github.com/greshake/i3status-rust/issues/668
            }
            {
              block = "sound";
              format = "{output_name} {volume}%";
              click = [{
                button = "left";
                cmd = "pavucontrol --tab=3";
              }];
              mappings = {
                "alsa_output.pci-0000_00_1f.3.analog-stereo" = "";
                "bluez_sink.70_26_05_DA_27_A4.a2dp_sink" = "";
              };
            }
            {
              block = "music";
              player = "spotify";
              buttons = [ "play" "prev" "next" ];
              click = [
                {
                  button = "play";
                  action = "music_play";
                }
                {
                  button = "prev";
                  action = "music_prev";
                }
                {
                  button = "next";
                  action = "music_next";
                }
              ];
            }
            {
              block = "time";
              interval = 60;
              format = " $timestamp.datetime(f:'%a %d/%m %R') ";
            }
            { block = "battery"; }
          ];

          icons = "awesome5";

          theme = "gruvbox-dark";
        };
      };
    };

    test.stubs.i3status-rust = { version = "0.30.0"; };

    nmt.script = ''
      assertFileExists home-files/.config/i3status-rust/config-custom.toml
      assertFileContent home-files/.config/i3status-rust/config-custom.toml \
        ${
          pkgs.writeText "i3status-rust-expected-config" ''
            [[block]]
            alert = 10.0
            block = "disk_space"
            info_type = "available"
            interval = 60
            path = "/"
            warning = 20.0

            [[block]]
            block = "memory"
            display_type = "memory"
            format_mem = "{Mug}GB ({Mup}%)"
            format_swap = "{SUp}%"

            [[block]]
            block = "cpu"
            format = " $icon $barchart "
            interval = 1

            [[block]]
            block = "load"
            format = " $icon $1m $5m "
            interval = 1

            [[block]]
            block = "temperature"
            chip = "*-isa-*"
            format = "$icon $min min, $max max, $average avg"
            interval = 10

            [[block]]
            block = "net"
            device = "enp9s0u2u1u2c2"
            interval = 5

            [[block]]
            block = "speedtest"
            format = " ^icon_ping $ping "

            [[block]]
            block = "xrandr"
            interval = 6000

            [[block]]
            block = "sound"
            format = "{output_name} {volume}%"

            [[block.click]]
            button = "left"
            cmd = "pavucontrol --tab=3"

            [block.mappings]
            "alsa_output.pci-0000_00_1f.3.analog-stereo" = ""
            "bluez_sink.70_26_05_DA_27_A4.a2dp_sink" = ""

            [[block]]
            block = "music"
            buttons = ["play", "prev", "next"]
            player = "spotify"

            [[block.click]]
            action = "music_play"
            button = "play"

            [[block.click]]
            action = "music_prev"
            button = "prev"

            [[block.click]]
            action = "music_next"
            button = "next"

            [[block]]
            block = "time"
            format = " $timestamp.datetime(f:'%a %d/%m %R') "
            interval = 60

            [[block]]
            block = "battery"

            [icons]
            icons = "awesome5"

            [theme]
            theme = "gruvbox-dark"
          ''
        }
    '';
  };
}
