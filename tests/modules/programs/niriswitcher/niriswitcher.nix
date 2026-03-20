{
  programs.niriswitcher = {
    enable = true;

    settings = {
      center_on_focus = true;
      keys = {
        modifier = "Super";
        switch = {
          next = "Tab";
          prev = "Shift+Tab";
        };
      };
      appearance = {
        system_theme = "dark";
        icon_size = 64;
      };
    };

    style = ./style.css;
  };

  nmt.script = ''
    assertFileExists home-files/.config/niriswitcher/config.toml
    assertFileContent home-files/.config/niriswitcher/config.toml ${./expected.toml}

    assertFileExists home-files/.config/niriswitcher/style.css
    assertFileContent home-files/.config/niriswitcher/style.css ${./style.css}
  '';
}
