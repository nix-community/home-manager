{ config, ... }:
{
  time = "2024-12-04T20:00:00+00:00";
  condition = config.programs.starship.enable;
  message = ''

    A new option 'programs.starship.enableInteractive' is available for
    the Fish shell that only enables starship if the shell is interactive.

    Some plugins require this to be set to 'false' to function correctly.
  '';
}
