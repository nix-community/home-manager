{
  programs.tray-tui = {
    enable = true;
    settings = {
      sorting = false;
      columns = 3;
      key_map = {
        left = "focus_left";
        h = "focus_left";
        right = "focus_right";
        l = "focus_right";
        up = "focus_up";
        j = "focus_up";
        down = "focus_down";
        k = "focus_down";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/tray-tui/config.toml
    assertFileContent home-files/.config/tray-tui/config.toml \
    ${./config.toml}
  '';
}
