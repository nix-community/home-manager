{ config, ... }:
{
  time = "2025-06-04T18:00:00+00:00";
  condition = config.programs.thunderbird.enable;
  message = ''
    'programs.thunderbird' now supports declaration of calendars using 'accounts.calendar.accounts'.
  '';
}
