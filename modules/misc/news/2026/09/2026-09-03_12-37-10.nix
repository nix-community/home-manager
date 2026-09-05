{ config, ... }:
{
  time = "2026-09-03T10:37:10+00:00";
  condition = config.programs.firefoxpwa.enable;
  message = ''
    The option `programs.firefoxpwa.profile.<name>.sites.<name>.manifestUrl` is
    now nullable to allow installing non-PWA websites.
  '';
}
