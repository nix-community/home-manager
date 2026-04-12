_: {
  programs.retroarch = {
    enable = true;
    coreSettings = {
      snes9x_aspect = "4:3";
      snes9x_overscan = "enabled";
      snes9x_region = "auto";
      mgba_solar_sensor_level = "0";
    };
  };

  nmt.script = ''
    coreOptionsFile=home-files/.config/retroarch/retroarch-core-options.cfg
    assertFileExists "$coreOptionsFile"
    assertFileContains "$coreOptionsFile" 'mgba_solar_sensor_level = "0"'
    assertFileContains "$coreOptionsFile" 'snes9x_aspect = "4:3"'
    assertFileContains "$coreOptionsFile" 'snes9x_overscan = "enabled"'
    assertFileContains "$coreOptionsFile" 'snes9x_region = "auto"'
  '';
}
