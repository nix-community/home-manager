{
  programs.hyfetch = {
    enable = true;

    settings = {
      preset = "rainbow";
      mode = "rgb";
      light_dark = "dark";
      lightness = 0.5;
      color_align = {
        mode = "horizontal";
        custom_colors = [ ];
        fore_back = null;
      };
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/hyfetch.json ${./hyfetch.json}
  '';
}
