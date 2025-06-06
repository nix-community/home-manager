{
  programs.wlr-which-key = {
    enable = true;

    commonSettings = {
      anchor = "center";
      background = "#282828d0";
      border = "#8ec07c";
      border_width = 2;
      color = "#fbf1c7";
      corner_r = 10;
      font = "JetBrainsMono Nerd Font 12";
      margin_bottom = 0;
      margin_left = 0;
      margin_right = 0;
      margin_top = 0;
      padding = 15;
      separator = " ➜ ";
    };

    # Example config in the README
    configs.config = {
      menu = {
        l = {
          desc = "Laptop Screen";
          submenu = {
            s = {
              desc = "Scale";
              submenu = {
                "1" = {
                  cmd = "wlr-randr --output eDP-1 --scale 1";
                  desc = "Set Scale to 1.0";
                };
                "2" = {
                  cmd = "wlr-randr --output eDP-1 --scale 1.1";
                  desc = "Set Scale to 1.1";
                };
                "3" = {
                  cmd = "wlr-randr --output eDP-1 --scale 1.2";
                  desc = "Set Scale to 1.2";
                };
                "4" = {
                  cmd = "wlr-randr --output eDP-1 --scale 1.3";
                  desc = "Set Scale to 1.3";
                };
              };
            };
            t = {
              cmd = "toggle-laptop-display.sh";
              desc = "Toggle On/Off";
            };
          };
        };
        p = {
          desc = "Power";
          submenu = {
            o = {
              cmd = "poweroff";
              desc = "Off";
            };
            r = {
              cmd = "reboot";
              desc = "Reboot";
            };
            s = {
              cmd = "systemctl suspend";
              desc = "Sleep";
            };
          };
        };
        t = {
          desc = "Theme";
          submenu = {
            d = {
              cmd = "dark-theme on";
              desc = "Dark";
            };
            l = {
              cmd = "dark-theme off";
              desc = "Light";
            };
            t = {
              cmd = "dark-theme toggle";
              desc = "Toggle";
            };
          };
        };
        w = {
          desc = "WiFi";
          submenu = {
            c = {
              cmd = "kitty --class nmtui-connect nmtui-connect";
              desc = "Connections";
            };
            t = {
              cmd = "wifi_toggle.sh";
              desc = "Toggle";
            };
          };
        };
      };
    };

    configs.other.menu.a = {
      cmd = "echo aaah";
      desc = "Say aaah";
    };
  };

  test.stubs.wlr-which-key = { };

  nmt.script = ''
    assertFileExists home-files/.config/wlr-which-key/config.yaml
    assertFileContent home-files/.config/wlr-which-key/config.yaml ${./expected-config.yaml}

    assertFileExists home-files/.config/wlr-which-key/other.yaml
    assertFileContent home-files/.config/wlr-which-key/other.yaml ${./expected-other.yaml}
  '';
}
