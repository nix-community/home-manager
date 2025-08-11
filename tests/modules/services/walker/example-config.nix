{
  services.walker = {
    enable = true;
    systemd.enable = true;
    settings = {
      app_launch_prefix = "";
      terminal_title_flag = "";
      locale = "";
      close_when_open = false;
      monitor = "";
      hotreload_theme = false;
      as_window = false;
      timeout = 0;
      disable_click_to_close = false;
      force_keyboard_focus = false;
    };

    theme = {
      name = "mytheme";
      layout = {
        ui = {
          anchors = {
            bottom = true;
            left = true;
            right = true;
            top = true;
          };

          window = {
            h_align = "fill";
            v_align = "fill";
          };
        };
      };
      style = ''
        * {
          color: #dcd7ba;
        }
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/walker/config.toml
    assertFileExists home-files/.config/walker/themes/mytheme.toml
    assertFileExists home-files/.config/walker/themes/mytheme.css

    assertFileContent home-files/.config/walker/config.toml \
    ${./config.toml}

    assertFileContent home-files/.config/walker/themes/mytheme.toml \
    ${./mytheme.toml}

    assertFileContent home-files/.config/walker/themes/mytheme.css \
    ${./mytheme.css}
  '';
}
