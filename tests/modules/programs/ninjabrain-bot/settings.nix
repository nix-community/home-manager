{
  programs.ninjabrain-bot = {
    enable = true;

    settings = {
      theme = 10;
      language_v2 = "fr-FR";
      always_on_top = true;
      sigma = 0.05;
      overlay_auto_hide = true;
      overlay_hide_delay = 45.0;
      hotkey_increment_modifier = 2;
      hotkey_increment_code = 65537;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.java/.userPrefs/ninjabrainbot/prefs.xml

    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml '<!DOCTYPE map SYSTEM "http://java.sun.com/dtd/preferences.dtd">'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="always_on_top" value="true"'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="language_v2" value="fr-FR"'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="overlay_auto_hide" value="true"'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="overlay_hide_delay" value="45.000000"'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="sigma" value="0.050000"'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="theme" value="10"'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="hotkey_increment_modifier" value="2"'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="hotkey_increment_code" value="65537"'
  '';
}
