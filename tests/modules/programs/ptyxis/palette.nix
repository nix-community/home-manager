{ pkgs, ... }:
{
  programs.ptyxis = {
    enable = true;
    defaultPalette = "myTheme";
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
    assertFileExists home-files/.local/share/org.gnome.Ptyxis/palettes/myTheme.palette
    assertFileContent home-files/.local/share/org.gnome.Ptyxis/palettes/myTheme.palette \
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

    dconfIni=$(grep -oPm 1 '/nix/store/[a-z0-9]*?-hm-dconf.ini' $TESTED/activate)
    assertFileContent $dconfIni ${pkgs.writeText "expected-ptyxis-dconf" ''
      [org/gnome/Ptyxis]
      default-profile-uuid='home-manager'
      profile-uuids=@as ['home-manager']

      [org/gnome/Ptyxis/Profiles/home-manager]
      palette='myTheme'
    ''}
  '';
}
