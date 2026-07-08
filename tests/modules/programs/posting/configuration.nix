{
  programs.posting = {
    enable = true;
    settings = {
      animation = "basic";
      heading = {
        show_host = false;
      };
      layout = "horizontal";
      response = {
        prettify_json = false;
      };
      theme = "custom";
    };
    themes = {
      custom = {
        name = "custom";
        primary = "#4e78c4";
        secondary = "#f39c12";
        accent = "#e74c3c";
        background = "#0e1726";
        surface = "#17202a";
        error = "#e74c3c";
        success = "#2ecc71";
        warning = "#f1c40f";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/posting/config.yaml
    assertFileContent home-files/.config/posting/config.yaml \
      ${./expected-config.yaml}

    assertFileExists home-files/.local/share/posting/themes/custom.yaml
    assertFileContent home-files/.local/share/posting/themes/custom.yaml \
      ${./expected-theme.yaml}
  '';
}
