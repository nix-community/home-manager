{ config, ... }:
{
  time = "2026-09-11T00:00:00+00:00";
  condition = config.services.xsuspender.enable;
  message = ''
    XSuspender now supports freeform INI configuration through
    `services.xsuspender.settings`. The deprecated `services.xsuspender.defaults`
    and `services.xsuspender.rules` aliases still work with their old defaults.

    See the 26.11 release notes before migrating, especially the changed
    defaults and empty-configuration behavior.
  '';
}
