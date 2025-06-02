{ config, ... }:

{
  time = "2024-12-10T22:20:10+00:00";
  condition = config.programs.nushell.enable;
  message = ''
    The module 'programs.nushell' can now manage the Nushell plugin
    registry with the option 'programs.nushell.plugins'.
  '';
}
