{
  programs.rofi = {
    enable = true;
    font = "Droid Sans Mono 14";
    terminal = "/some/path";
    cycle = false;
    window = {
      background = "background";
      border = "border";
      separator = "separator";
    };
    modes = [
      "drun"
      "emoji"
      "ssh"
      {
        name = "foo";
        path = "bar";
      }
    ];
    extraConfig = {
      combi-modes = [
        "window"
        "drun"
      ];
      kb-primary-paste = "Control+V,Shift+Insert";
      kb-secondary-paste = "Control+v,Insert";
      modi = [
        "run"
        "drun"
        "window"
        "ssh"
      ];
      drun = {
        display-name = "";
      };
      "run,drun" = {
        display-name = "open:";
      };
      filebrowser = {
        directory = "$HOME";
        sorting-method = "name";
        directories-first = true;
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/rofi/config.rasi \
      ${./valid-config-expected.rasi}
  '';
}
