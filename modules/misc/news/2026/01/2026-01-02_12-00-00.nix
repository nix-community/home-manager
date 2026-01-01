{ config, ... }:
{
  time = "2026-01-02T12:00:00+00:00";
  condition = config.programs.lnav.enable;
  message = ''
    A new module is available: 'programs.lnav'.

    lnav is a log file navigator that provides an advanced interface for
    viewing and analyzing log files. The module supports configuration via
    'settings' and custom log format files via 'formats'.

    See https://docs.lnav.org/ for more information.
  '';
}
