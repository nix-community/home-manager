{
  programs.yazi = {
    enable = true;

    plugins = {
      dual-pane = {
        package = ./plugin;
        setup = true;
      };
      yatline = {
        package = ./plugin;
        setup = true;
        settings = {
          section_separator = {
            open = "";
            close = "";
          };
          tab_width = 20;
        };
      };
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/yazi/init.lua \
      ${./configurations-expected.lua}
  '';
}
