{ config, pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    autoThemeFiles = {
      light = "GitHub";
      dark = "TokyoNight";
      noPreference = "OneDark";
    };
  };

  test = {
    assertFileExists = [
      "home-files/.config/kitty/light-theme.auto.conf"
      "home-files/.config/kitty/dark-theme.auto.conf"
      "home-files/.config/kitty/no-preference-theme.auto.conf"
    ];
    assertFileRegex = [
      "home-files/.config/kitty/light-theme.auto.conf"
      "^include .*themes/GitHub\\.conf$"
      "home-files/.config/kitty/dark-theme.auto.conf"
      "^include .*themes/TokyoNight\\.conf$"
      "home-files/.config/kitty/no-preference-theme.auto.conf"
      "^include .*themes/OneDark\\.conf$"
    ];
  };
}
