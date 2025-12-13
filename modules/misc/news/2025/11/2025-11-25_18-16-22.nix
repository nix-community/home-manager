{ config, ... }:
{
  time = "2025-11-25T17:16:22+00:00";
  condition = config.programs.starship.enable;
  message = ''
    The starship module has a new option, programs.starship.presets, which allows for merging user configuration with bundled presets.
  '';
}
