{ config, ... }:
{
  time = "2026-06-13T11:54:31+00:00";
  condition = config.programs.swayimg.enable;
  message = ''
    `programs.swayimg.settings` has been replaced with
    `programs.swayimg.initLua` because upstream moved to a lua config.
  '';
}
