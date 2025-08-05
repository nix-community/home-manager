{ config, ... }:
{
  time = "2025-07-10T20:33:18+00:00";
  condition = config.programs.firefox.enable;
  message = ''
    The 'programs.firefox' module now supports extension permissions configuration.

    A new 'profiles.<name>.extensions.settings.<name>.permissions' option allows
    declarative control over Firefox extension permissions, enhancing security
    by explicitly managing what permissions extensions have access to.
  '';
}
