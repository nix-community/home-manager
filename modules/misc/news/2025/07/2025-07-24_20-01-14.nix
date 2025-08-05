{ config, ... }:
{
  time = "2025-07-24T20:01:14+00:00";
  condition = config.programs.trippy.enable;
  message = ''
    The 'programs.trippy' module now supports the 'forceUserConfig' option.

    This option allows forcing the use of user configuration even when
    running as root, providing more consistent behavior across different
    execution contexts.
  '';
}
