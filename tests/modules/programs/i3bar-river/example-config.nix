{
  programs.i3bar-river = {
    enable = true;
    settings = {
      background = "#282828ff";
      color = "#ffffffff";
      separator = "#9a8a62ff";
      font = "monospace 10";
      height = 24;
      margin_top = 0;
      margin_bottom = 0;
      margin_left = 0;
      "wm.river" = {
        max_tag = 0;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/i3bar-river/config.toml
    assertFileContent home-files/.config/i3bar-river/config.toml \
    ${./config.toml}
  '';
}
