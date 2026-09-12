{ config, ... }:
{
  time = "2026-09-11T00:00:00+00:00";
  condition = config.programs.rofi.enable;
  message = ''
    Rofi now uses `programs.rofi.settings` for its Rasi configuration block.
    `programs.rofi.extraConfig` remains a deprecated alias. The former font,
    terminal, cycle, location, offset, and modes options provide compatibility
    defaults. Use numeric locations and `"name:path"` strings for script modes
    in settings.
    Theme and package configuration are unchanged.
  '';
}
