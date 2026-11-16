{ config, ... }:
{
  time = "2025-12-28T11:43:43+00:00";
  condition = config.services.mpd-mpris.enable;
  message = ''
    An update to the `services.mpd-mpris` module introduced breaking changes:

    - Settings have moved from the `services.mpd-mpris.mpd` namespace to
      `services.mpd-mpris.settings`. The `pwd` option was removed in favour
      of a more secure `pwd-file` option.

    - The `services.mpd-mpris.mpd.useLocal` option was removed. `mpd-mpris`
      will automatically try to connect with the local MPD instance if the
      `services.mpd-mpris.settings.host` option is not set (the default).
  '';
}
