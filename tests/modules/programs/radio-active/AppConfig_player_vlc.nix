{
  programs.radio-active = {
    enable = true;

    settings.AppConfig.player = "vlc";
  };

  nmt.script = ''
    assertFileExists home-files/.config/radio-active/configs.ini
    assertFileContent home-files/.config/radio-active/configs.ini \
    ${builtins.toFile "expected.player_mpv.radio-active_configs.ini" ''
      [AppConfig]
      player=vlc
    ''}
  '';
}
