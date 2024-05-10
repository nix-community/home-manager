{ pkgs, ... }:

let themeName = "dracula";
in {
  programs.silicon = {
    enable = true;
    themes = {
      ${themeName} = {
        src = pkgs.fetchFromGitHub {
          owner = "dracula";
          repo = "sublime";
          rev = "26c57ec282abcaa76e57e055f38432bd827ac34e";
          sha256 = "019hfl4zbn4vm4154hh3bwk6hm7bdxbr1hdww83nabxwjn99ndhv";
        };
        file = "Dracula.tmTheme";
      };
    };
  };

  test.stubs.silicon = { };

  nmt.script = let
    themeFile = "home-files/.config/silicon/themes/${themeName}.tmTheme";
    cacheFile = "home-files/.cache/silicon/themes.bin";
  in ''
    assertFileExists "${themeFile}"
    assertFileExists "${cacheFile}"
  '';
}
