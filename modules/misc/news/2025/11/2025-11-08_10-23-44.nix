{ config, ... }:
{
  time = "2025-11-08T15:23:44+00:00";
  condition = config.programs.vicinae.themes != { };
  message = ''
    Vicinae theme definitions have been updated to a new format. See https://docs.vicinae.com/theming/getting-started for the new structure.
  '';
}
