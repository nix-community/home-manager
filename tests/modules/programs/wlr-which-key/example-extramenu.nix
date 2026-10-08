{
  programs.wlr-which-key = {
    enable = true;
    extraMenus = {
      browsers = {
        font = "monospace 12";
        background = "#141617d0";
        color = "#ddc7a1";
        border = "#d3869b";

        border_width = 2;
        corner_r = 10;
        rows_per_column = 5;
        column_padding = 25;
        anchor = "bottom-right";

        inhibit_compositor_keyboard_shortcuts = true;

        menu = [
          {
            key = "f";
            desc = "Firefox";
            cmd = "firefox";
          }
          {
            key = "q";
            desc = "Qutebrowser";
            cmd = "qutebrowser";
          }
        ];
      };
    };
  };

  nmt.script = ''
    local configFile=home-files/.config/wlr-which-key/browsers.yaml
    assertFileExists $configFile
    assertFileContent $configFile ${./example-extramenu.yaml}
  '';
}
