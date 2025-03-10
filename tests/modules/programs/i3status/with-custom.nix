{ config, ... }:

{
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

    package = config.lib.test.mkStubPackage { };

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

  nmt.script = ''
    assertFileContent \
      home-files/.config/i3status/config \
      ${
        builtins.toFile "i3status-expected-config" ''
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
}
