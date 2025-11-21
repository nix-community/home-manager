{
  programs.atuin = {
    enable = true;

    themes.my-theme = {
      theme.name = "My Theme";
      colors = {
        Base = "#000000";
        Title = "#FFFFFF";
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/atuin/themes/my-theme.toml \
      ${builtins.toFile "example-theme-expected.toml" ''
        [colors]
        Base = "#000000"
        Title = "#FFFFFF"

        [theme]
        name = "My Theme"
      ''}
  '';
}
