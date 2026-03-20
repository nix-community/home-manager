{ config, ... }:
{
  time = "2026-01-11T16:02:12+00:00";
  condition = config.programs.starship.enable;
  message = ''
    The starship module has a new option, programs.starship.presets, which
    allows for merging user configuration with Starship's bundled presets.
  '';
}
