{
  programs.alacritty = {
    enable = true;
    settings = {
      window.dimensions = {
        lines = 3;
        columns = 200;
      };

      keyboard.bindings = [
        {
          key = "K";
          mods = "Control";
          chars = "\\u000c";
        }
        {
          key = "RBracket";
          mods = "Alt";
          chars = "\\u001d";
        }
        {
          key = "Back";
          mods = "Shift";
          chars = "\\u001b[3~";
        }
        {
          key = "Delete";
          mods = "Shift";
          chars = "\\^[[3~";
        }
        {
          key = "A";
          mods = "Control";
          chars = "\\u0000";
        }
        {
          key = "Up";
          mods = "Control";
          chars = "\\u001b\\u001b";
        }
        {
          key = "Down";
          mods = "Control";
          chars = "OK\\u001b";
        }
        {
          key = "Left";
          mods = "Control";
          chars = "\\^[\\^[";
        }
      ];

      font = {
        normal.family = "SFMono";
        bold.family = "SFMono";
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/alacritty/alacritty.toml \
      ${./settings-toml-expected.toml}
  '';
}
