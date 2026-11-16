{ config, pkgs, ... }:

let
  inherit (pkgs) formats writeText;

  jsonFormat = formats.json { };

  cfg = config.programs.gram;

  expectedTheme = jsonFormat.generate "my-cool-theme.json" cfg.themes.my-cool-theme;
  expectedFoobar = writeText "foobar.json" cfg.themes."foobar.json";
in

{
  programs.gram = {
    enable = true;

    themes = {
      my-cool-theme = {
        name = "My Cool Theme";
        author = "You!";
        themes = [
          {
            name = "My Cool Dark Theme";
            appearance = "dark";
            style."editor.background" = "#000";
          }
          {
            name = "My Cool Light Theme";
            appearance = "light";
            style."editor.background" = "#fff";
          }
        ];
      };
      "foobar.json" = ''
        This should be written as-is.
      '';
    };
  };

  nmt.script = ''
    themesDir=home-files/.config/gram/themes

    assertFileExists $themesDir/my-cool-theme.json
    assertFileContent $themesDir/my-cool-theme.json ${expectedTheme}

    assertFileExists $themesDir/foobar.json
    assertFileContent $themesDir/foobar.json ${expectedFoobar}
  '';
}
