{ config, lib, pkgs, ... }:

{
  config = {
    programs.i3status-rust = {
      enable = true;

      bars = {

        top = {
          blocks = [
            {
              block = "disk_space";
              info_type = "available";
              interval = 60;
              warning = 20.0;
              alert = 10.0;
            }
            {
              block = "memory";
              format_mem = " $icon $Mug ($Mup) ";
              format_swap = " $icon $SUp ";
            }
          ];
        };

        bottom = {
          blocks = [
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
          ];
          icons = "awesome5";

          theme = "gruvbox-dark";
        };

      };

    };

    test.stubs.i3status-rust = { version = "0.30.0"; };

    nmt.script = ''
      assertFileExists home-files/.config/i3status-rust/config-top.toml
      assertFileContent home-files/.config/i3status-rust/config-top.toml \
        ${
          pkgs.writeText "i3status-rust-expected-config" ''
            [[block]]
            alert = 10.0
            block = "disk_space"
            info_type = "available"
            interval = 60
            warning = 20.0

            [[block]]
            block = "memory"
            format_mem = " $icon $Mug ($Mup) "
            format_swap = " $icon $SUp "

            [icons]
            icons = "none"

            [theme]
            theme = "plain"
          ''
        }

      assertFileExists home-files/.config/i3status-rust/config-bottom.toml
      assertFileContent \
        home-files/.config/i3status-rust/config-bottom.toml \
        ${
          pkgs.writeText "i3status-rust-expected-config" ''
            [[block]]
            block = "cpu"
            format = " $icon $barchart "
            interval = 1

            [[block]]
            block = "load"
            format = " $icon $1m $5m "
            interval = 1

            [icons]
            icons = "awesome5"

            [theme]
            theme = "gruvbox-dark"
          ''
        }
    '';
  };
}
