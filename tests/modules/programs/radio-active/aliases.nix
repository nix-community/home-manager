{
  programs.radio-active = {
    enable = true;
    package = null;

    aliases = {
      "Deep House Lounge" = "http://198.15.94.34:8006/stream";
    };

    settings.Favorites = {
      station = "Deep House Lounge";
      volume = 42;
    };
  };

  test.stubs.radio-active = {
    name = "radio-active-default";
    outPath = null;
    buildScript = ''
      mkdir -p "$out/bin"
      touch "$out/bin/radio-active"
    '';
  };

  nmt.script = ''
    assertPathNotExists home-path/bin/radio-active

    assertFileExists home-files/.config/radio-active/configs.ini
    assertFileContent home-files/.config/radio-active/configs.ini \
    ${builtins.toFile "expected.radio-active_favorites.ini" ''
      [Favorites]
      station=Deep House Lounge
      volume=42
    ''}

    assertFileExists home-files/.radio-active-alias
    assertFileContent home-files/.radio-active-alias \
    ${builtins.toFile "expected.radio-active_aliases.ini" ''
      Deep House Lounge==http://198.15.94.34:8006/stream
    ''}
  '';
}
