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
      kb-primary-paste = "Control+V,Shift+Insert";
      kb-secondary-paste = "Control+v,Insert";
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/rofi/config.rasi \
      ${./valid-config-expected.rasi}
  '';
}
