{ config, ... }:
{
  time = "2026-07-05T00:00:00+00:00";
  condition = config.programs.wrtag.enable;
  message = ''
    A new module is available: `programs.wrtag`.

    wrtag is a music tagging and organisation tool based on MusicBrainz.

    Configuration is written in flagconf format and supports stackable
    options such as `addon`, `keep-file`, and `notification-uri`. The
    module respects `home.preferXdgDirectories` on macOS.
  '';
}
