{ config, lib, pkgs, ... }:

{
  config = {
    programs.i3status-rust = { enable = true; };

    test.stubs.i3status-rust = { version = "0.29.9"; };

    nmt.script = ''
      assertFileExists home-files/.config/i3status-rust/config-default.toml
      assertFileContent home-files/.config/i3status-rust/config-default.toml \
        ${
          pkgs.writeText "i3status-rust-expected-config" ''
            icons = "none"
            theme = "plain"
            [[block]]
            alert = 10.0
            block = "disk_space"
            info_type = "available"
            interval = 60
            path = "/"
            warning = 20.0

            [[block]]
            block = "memory"
            format = " $icon mem_used_percents "
            format_alt = " $icon $swap_used_percents "

            [[block]]
            block = "cpu"
            interval = 1

            [[block]]
            block = "load"
            format = " $icon $1m "
            interval = 1

            [[block]]
            block = "sound"

            [[block]]
            block = "time"
            format = " $timestamp.datetime(f:'%a %d/%m %R') "
            interval = 60
          ''
        }
    '';
  };
}
