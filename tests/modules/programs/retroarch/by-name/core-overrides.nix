{ config, pkgs, ... }:
let
  configDir = "home-files/.config/retroarch";
  absoluteConfigDir = "${config.xdg.configHome}/retroarch";
in
{
  programs.retroarch = {
    enable = true;
    cores."Snes9x - Current" = {
      enable = true;
      package = pkgs.libretro.snes9x2010;
      settingsOverrides = {
        video_fullscreen = "true";
      };
      inputRemaps = {
        input_player1_a_btn = "1";
      };
      perContentDirectory."SNES" = {
        settingsOverrides = {
          video_smooth = "true";
        };
        inputRemaps = {
          input_player1_b_btn = "0";
        };
      };
      perGame."Chrono Trigger" = {
        settingsOverrides = {
          video_scale = "5.0";
        };
        inputRemaps = {
          input_player1_x_btn = "9";
        };
      };
    };
  };

  nmt.script = ''
    retroarchConfig="${configDir}/retroarch.cfg"
    assertFileContains "$retroarchConfig" 'remap_save_on_exit = "false"'
    assertFileContains "$retroarchConfig" \
      'rgui_config_directory = "${absoluteConfigDir}/config"'
    assertFileContains "$retroarchConfig" \
      'input_remapping_directory = "${absoluteConfigDir}/config/remaps"'

    coreDir="${configDir}/config/Snes9x - Current"
    remapDir="${configDir}/config/remaps/Snes9x - Current"

    coreOverride="$coreDir/Snes9x - Current.cfg"
    assertFileExists "$coreOverride"
    assertFileContains "$coreOverride" 'video_fullscreen = "true"'

    directoryOverride="$coreDir/SNES.cfg"
    assertFileExists "$directoryOverride"
    assertFileContains "$directoryOverride" 'video_smooth = "true"'

    gameOverride="$coreDir/Chrono Trigger.cfg"
    assertFileExists "$gameOverride"
    assertFileContains "$gameOverride" 'video_scale = "5.0"'

    coreRemap="$remapDir/Snes9x - Current.rmp"
    assertFileExists "$coreRemap"
    assertFileContains "$coreRemap" 'input_player1_a_btn = "1"'

    directoryRemap="$remapDir/SNES.rmp"
    assertFileExists "$directoryRemap"
    assertFileContains "$directoryRemap" 'input_player1_b_btn = "0"'

    gameRemap="$remapDir/Chrono Trigger.rmp"
    assertFileExists "$gameRemap"
    assertFileContains "$gameRemap" 'input_player1_x_btn = "9"'
  '';
}
