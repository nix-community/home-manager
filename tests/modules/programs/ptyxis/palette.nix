{ pkgs, ... }:
{
  programs.ptyxis = {
    enable = true;
    palettes.myTheme = {
      Palette.Name = "My awesome theme";
      Light = {
        Foreground = "#E2E2E3";
        Background = "#2C2E34";
        Color0 = "#2C2E34";
        Color1 = "#FC5D7C";
        Color2 = "#9ED072";
        Color3 = "#E7C664";
        Color4 = "#F39660";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/org.gnome.Prompt/palettes/myTheme.palette
    assertFileContent home-files/.config/org.gnome.Prompt/palettes/myTheme.palette \
      ${pkgs.writeText "expected-ptyxis-theme" ''
        [Light]
        Background=#2C2E34
        Color0=#2C2E34
        Color1=#FC5D7C
        Color2=#9ED072
        Color3=#E7C664
        Color4=#F39660
        Foreground=#E2E2E3

        [Palette]
        Name=My awesome theme
      ''}
  '';
}
