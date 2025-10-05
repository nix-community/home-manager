{
  services.hyprshell = {
    enable = true;
    settings = {
      version = 3;
      windows = {
        scale = 8.5;
        items_per_row = 5;
        overview = {
          key = "super_l";
          modifier = "super";
          launcher = {
            default_terminal = "alacritty";
          };
        };
        switch = {
          modifier = "alt";
        };
      };
    };
    style = ./styles.css;
  };

  nmt.script = ''
    assertFileExists home-files/.config/hyprshell/config.json
    assertFileExists home-files/.config/hyprshell/styles.css

    assertFileContent home-files/.config/hyprshell/config.json \
    ${./config.json}

    assertFileContent home-files/.config/hyprshell/styles.css \
    ${./styles.css}
  '';
}
