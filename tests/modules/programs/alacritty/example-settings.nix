{
  programs.alacritty = {
    enable = true;
    theme = "catppuccin_mocha";
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
      ];
    };
  };

  nmt.script = ''
    tomlFile=home-files/.config/alacritty/alacritty.toml

    assertFileExists $tomlFile

    assertFileRegex $tomlFile '^import = '

    assertFileRegex $tomlFile '[[keyboard.bindings]]'
    assertFileRegex $tomlFile 'chars = "\\u000c"'
    assertFileRegex $tomlFile 'key = "K"'
    assertFileRegex $tomlFile 'mods = "Control"'

    assertFileRegex $tomlFile '[window.dimensions]'
    assertFileRegex $tomlFile 'columns = 200'
    assertFileRegex $tomlFile 'lines = 3'
  '';
}
