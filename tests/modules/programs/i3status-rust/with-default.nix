{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.i3status-rust = { enable = true; };

    test.stubs.i3status-rust = { };

    nmt.script = ''
      assertFileExists home-files/.config/i3status-rust/config-default.toml
      assertFileContent home-files/.config/i3status-rust/config-default.toml \
        ${
          pkgs.writeText "i3status-rust-expected-config" ''
            icons = "none"
            theme = "plain"
            [[block]]
            alert = 10.0
            alias = "/"
            block = "disk_space"
            info_type = "available"
            interval = 60
            path = "/"
            unit = "GB"
            warning = 20.0

            [[block]]
            block = "memory"
            display_type = "memory"
            format_mem = "{mem_used_percents}"
            format_swap = "{swap_used_percents}"

            [[block]]
            block = "cpu"
            interval = 1

            [[block]]
            block = "load"
            format = "{1m}"
            interval = 1

            [[block]]
            block = "sound"

            [[block]]
            block = "time"
            format = "%a %d/%m %R"
            interval = 60
          ''
        }
    '';
  };
}
