{ pkgs, ... }:
{
  programs.retroarch = {
    enable = true;
    cores."Snes9x - Current" = {
      enable = true;
      package = pkgs.libretro.snes9x2010;
      options = {
        snes9x_aspect = "4:3";
        snes9x_region = "auto";
      };
      perGame."Chrono Trigger".options = {
        snes9x_region = "ntsc";
      };
    };
  };

  nmt.script = ''
    retroarchConfig="home-files/.config/retroarch/retroarch.cfg"
    assertFileContains "$retroarchConfig" 'game_specific_options = "true"'
    assertFileContains "$retroarchConfig" 'global_core_options = "true"'

    coreOptions="home-files/.config/retroarch/retroarch-core-options.cfg"
    assertFileExists "$coreOptions"
    assertFileContains "$coreOptions" 'snes9x_aspect = "4:3"'
    assertFileContains "$coreOptions" 'snes9x_region = "auto"'

    gameOptions="home-files/.config/retroarch/config/Snes9x - Current/Chrono Trigger.opt"
    assertFileExists "$gameOptions"
    assertFileContains "$gameOptions" 'snes9x_region = "ntsc"'
  '';
}
