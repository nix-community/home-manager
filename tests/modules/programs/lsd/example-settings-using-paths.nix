{
  programs.lsd = {
    enable = true;
    settings = {
      date = "relative";
      blocks = [
        "date"
        "size"
        "name"
      ];
      layout = "oneline";
      sorting.dir-grouping = "first";
      ignore-globs = [
        ".git"
        ".hg"
        ".bsp"
      ];
    };
    colors = ./example-colors-expected.yaml;
    icons = ./example-icons-expected.yaml;
  };

  nmt.script = ''
    assertFileExists home-files/.config/lsd/config.yaml
    assertFileExists home-files/.config/lsd/colors.yaml
    assertFileExists home-files/.config/lsd/icons.yaml
    assertFileContent \
      home-files/.config/lsd/config.yaml \
      ${./example-settings-expected.yaml}
    assertFileContent \
      home-files/.config/lsd/colors.yaml \
      ${./example-colors-expected.yaml}
    assertFileContent \
      home-files/.config/lsd/icons.yaml \
      ${./example-icons-expected.yaml}
  '';
}
