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
      style = ''
        * {
          color: #dcd7ba;
        }
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/walker/config.toml
    assertFileExists home-files/.config/walker/themes/mytheme/style.css

    assertFileContent home-files/.config/walker/config.toml \
    ${./config.toml}

    assertFileContent home-files/.config/walker/themes/mytheme/style.css \
    ${./mytheme.css}
  '';
}
