{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.i3status-rust = {
      enable = true;

      bars = {

        top = {
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
          ];
        };

        bottom = {
          blocks = [
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
          ];
          icons = "awesome5";

          theme = "gruvbox-dark";
        };

      };

    };

    nixpkgs.overlays = [
      (self: super: {
        i3status-rust = pkgs.writeScriptBin "dummy-i3status-rust" "";
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.config/i3status-rust/config-top.toml
      assertFileContent home-files/.config/i3status-rust/config-top.toml \
        ${
          pkgs.writeText "i3status-rust-expected-config" ''
            icons = "none"
            theme = "plain"
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
          ''
        }

      assertFileExists home-files/.config/i3status-rust/config-bottom.toml
      assertFileContent \
        home-files/.config/i3status-rust/config-bottom.toml \
        ${
          pkgs.writeText "i3status-rust-expected-config" ''
            icons = "awesome5"
            theme = "gruvbox-dark"
            [[block]]
            block = "cpu"
            format = "{barchart}"
            interval = 1

            [[block]]
            block = "load"
            format = "{1m} {5m}"
            interval = 1
          ''
        }
    '';
  };
}
