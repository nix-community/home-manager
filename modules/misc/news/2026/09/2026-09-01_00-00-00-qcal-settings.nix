{ config, ... }:
{
  time = "2026-09-01T00:00:00+00:00";
  condition = config.programs.qcal.enable;
  message = ''
    The qcal module now exposes its JSON configuration through
    `programs.qcal.settings` and per-calendar entries through
    `accounts.calendar.accounts.<name>.qcal.settings`.

    `programs.qcal.timezone` and `programs.qcal.defaultNumDays` are
    deprecated aliases of `programs.qcal.settings.Timezone` and
    `programs.qcal.settings.DefaultNumDays`.
  '';
}
