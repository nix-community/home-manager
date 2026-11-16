{
  programs.ninjabrain-bot.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.java/.userPrefs/ninjabrainbot/prefs.xml
  '';
}
