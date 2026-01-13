{ config, ... }:
{
  time = "2026-01-02T00:03:48+00:00";
  condition = config.services.mpd.enable;
  message = ''
    `MPD_HOST` and `MPD_PORT` environment variables are now set automatically.

    This can be disabled with `services.mpd.enableSessionVariables = false`.
  '';
}
