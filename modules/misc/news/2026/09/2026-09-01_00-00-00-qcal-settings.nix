{ config, ... }:
{
  time = "2026-09-01T00:00:00+00:00";
  condition = config.programs.qcal.enable;
  message = ''
    Qcal now supports root settings with `programs.qcal.settings` and
    per-account settings with `accounts.calendar.accounts.<name>.qcal.settings`.
    Existing `programs.qcal.timezone` and `programs.qcal.defaultNumDays`
    configurations continue to work through compatibility aliases. New
    configurations should use `programs.qcal.settings.Timezone` and
    `programs.qcal.settings.DefaultNumDays`.
  '';
}
