{
  programs.radio-active = {
    enable = true;

    settings.AppConfig = {
      filepath = "/mnt/{user}/recordings/radioactive/";
      filetype = "auto";
      filter = "name=shows";
      limit = 41;
      loglevel = "debug";
      player = "ffplay";
      sort = "random";
      volume = 68;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/radio-active/configs.ini
    assertFileContent home-files/.config/radio-active/configs.ini \
    ${builtins.toFile "expected.radio-active_configs.ini" ''
      [AppConfig]
      filepath=/mnt/{user}/recordings/radioactive/
      filetype=auto
      filter=name=shows
      limit=41
      loglevel=debug
      player=ffplay
      sort=random
      volume=68
    ''}
  '';
}
