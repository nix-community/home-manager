{ config, ... }:

{
  time = "2026-05-18T03:07:36+00:00";
  condition = config.services.walker.enable;
  message = ''
    The 'services.walker' module now supports Elephant integration through
    {option}`services.walker.enableElephantIntegration`.

    When both `services.walker` and `services.elephant` are enabled, Walker's
    systemd user service now starts after `elephant.service` and requires it.
    Set {option}`services.walker.enableElephantIntegration` to `false` to
    disable this service dependency.
  '';
}
