{ config, ... }:

{
  time = "2025-10-03T19:09:14+00:00";
  condition = config.programs.aliae.enable;
  message = ''
    A new option `programs.aliae.configLocation` is now available.

    It allows you to set where you want to place the config file.
  '';
}
