{ config, ... }:
{
  time = "2026-09-16T00:00:00+00:00";
  condition = config.services.mpdris2.enable;
  message = ''
    mpDris2 now supports freeform INI configuration through
    `services.mpdris2.settings`, including cover matching and notification
    formatting, timeout, and urgency. Existing options remain supported with
    migration warnings. The generated `music_dir` setting now uses mpDris2's
    native `Library` section.
  '';
}
