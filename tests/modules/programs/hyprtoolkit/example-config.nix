{
  programs.hyprtoolkit = {
    enable = true;
    settings = {
      background = "0xFF181818";
      base = "0xFF202020";
      h1_size = 19;
      h2_size = 15;
      h3_size = 13;
      font_size = 11;
      font_family = "Sans Serif";
    };
  };

  nmt.script = ''
    assertFileExists \
      "home-files/.config/hypr/hyprtoolkit.conf"

    assertFileContent \
      "home-files/.config/hypr/hyprtoolkit.conf" \
      ${./example-hyprtoolkit.conf}
  '';
}
