{
  services.hyprshell = {
    enable = true;
    settings = {
      layerrules = true;
      kill_bind = "ctrl+shift+alt, h";
      version = 1;
      windows = {
        scale = 8.5;
        items_per_row = 5;
      };
    };
    style = ./style.css;
  };

  nmt.script = ''
    assertFileExists home-files/.config/hyprshell/config.json
    assertFileExists home-files/.config/hyprshell/style.css

    assertFileContent home-files/.config/hyprshell/config.json \
    ${./config.json}

    assertFileContent home-files/.config/hyprshell/style.css \
    ${./style.css}
  '';
}
