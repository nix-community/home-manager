{ config, ... }:
{
  time = "2026-08-13T00:00:00+00:00";
  condition = config.programs.mpv.enable;
  message = ''
    `programs.mpv.config` is now `programs.mpv.settings`. The old option remains
    available as a deprecated alias.
  '';
}
