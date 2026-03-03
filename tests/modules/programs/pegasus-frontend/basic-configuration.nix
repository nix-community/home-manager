{ ... }:
{
  config = {
    programs.pegasus-frontend = {
      enable = true;
    };

    nmt.script = ''
      cfg=home-files/.config/pegasus-frontend

      assertFileExists $cfg/settings.txt
      assertFileContent $cfg/settings.txt ${./basic-settings.txt}

      assertFileExists $cfg/game_dirs.txt
      assertPathNotExists $cfg/favorites.txt
      assertPathNotExists $cfg/themes
      assertPathNotExists $cfg/theme_settings
    '';
  };
}
