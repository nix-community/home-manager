{
  programs.ninjabrain-bot = {
    enable = true;

    settings = {
      theme = 10;
      language = "fr-FR";
      windowSize = "large";
      strongholdDisplay = "chunk";
      view = "detailed";
      minecraftVersion = "1.19+";
      autoReset = false;
      showAngleErrors = true;
      useAlternativeStandardDeviation = true;
      usePreciseAngle = true;
      useObsOverlay = true;
      overlayAutoHide = true;
      overlayHideWhenLocked = true;
      overlayHideDelay = 45.0;
      allAdvancements = true;
      oneDotTwentyPlusAllAdvancements = true;
      allAdvancementsToggle = "hotkey";
      angleAdjustmentType = "custom";
      angleAdjustmentDisplay = "increments";
      customAdjustment = 0.02;
      hotkeys = {
        increment = {
          modifier = 2;
          keyCode = 65537;
        };
        boat = {
          modifier = 0;
          keyCode = 65538;
        };
        toggleAllAdvancements = {
          modifier = 1;
          keyCode = 65539;
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.java/.userPrefs/ninjabrainbot/prefs.xml

    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml '<!DOCTYPE map SYSTEM "http://java.sun.com/dtd/preferences.dtd">'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="language_v2" value="fr-FR"'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="size" value="2"'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="stronghold_display_type" value="2"'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="mc_version" value="1"'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="overlay_auto_hide" value="true"'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="overlay_hide_delay" value="45.000000"'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="one_dot_twenty_plus_aa" value="true"'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="angle_adjustment_type" value="2"'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="hotkey_increment_modifier" value="2"'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="hotkey_increment_code" value="65537"'
    assertFileContains home-files/.java/.userPrefs/ninjabrainbot/prefs.xml 'key="hotkey_toggle_aa_mode_code" value="65539"'
  '';
}
