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
    Unset location and offset options now use Rofi's defaults instead of
    writing zero values. Explicit legacy values are still migrated.
    Enabling Rofi alone no longer generates a configuration file; configure
    settings or a theme to generate one. Theme and package options are unchanged.
  '';
}
