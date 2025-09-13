{
  programs.radio-active = {
    enable = true;

    settings.AppConfig.player = "vlc";
  };

  nmt.script = ''
    assertFileExists home-files/.config/radio-active/configs.ini
    assertFileContent home-files/.config/radio-active/configs.ini \
    ${./AppConfig_player_vlc.ini}
  '';
}
