{
  programs.radio-active = {
    enable = true;

    settings.AppConfig = {
      filepath = "/home/{user}/recordings/radioactive/";
      filetype = "mp3";
      filter = "none";
      limit = 41;
      loglevel = "debug";
      player = "ffplay";
      sort = "votes";
      volume = 68;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/radio-active/configs.ini
    assertFileContent home-files/.config/radio-active/configs.ini \
    ${builtins.toFile "expected.all.radio-active_configs.ini" ''
      [AppConfig]
      filepath=/home/{user}/recordings/radioactive/
      filetype=mp3
      filter=none
      limit=41
      loglevel=debug
      player=ffplay
      sort=votes
      volume=68
    ''}
  '';
}
