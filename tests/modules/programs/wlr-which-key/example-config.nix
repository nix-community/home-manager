{
  programs.wlr-which-key = {
    enable = true;
    settings = {
      font = "monospace 12";
      background = "#141617d0";
      color = "#ddc7a1";
      border = "#d3869b";

      border_width = 2;
      corner_r = 10;
      rows_per_column = 25;
      anchor = "bottom-right";

      inhibit_compositor_keyboard_shortcuts = true;

      menu = [
        {
          key = "c";
          desc = "clipboard";
          cmd = "noctalia msg panel-toggle clipboard";
        }
        {
          key = "Return";
          desc = "Terminal";
          cmd = "xdg-terminal-exec || kitty";
        }
      ];
    };
  };
  nmt.script = ''
    local configFile=home-files/.config/wlr-which-key/config.yaml
    assertFileExists $configFile
    assertFileContent $configFile \
      ${./example-config.yaml}
  '';
}
