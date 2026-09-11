{ config, ... }:
{
  time = "2026-09-11T15:23:56+00:00";
  condition = config.services.twmn.enable;
  message = ''
    TWMN now supports freeform INI configuration through
    'services.twmn.settings'. Legacy options remain supported with
    migration warnings.
  '';
}
