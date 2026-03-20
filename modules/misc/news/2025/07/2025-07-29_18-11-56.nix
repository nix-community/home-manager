{ config, ... }:
{
  time = "2025-07-29T18:11:56+00:00";
  condition = config.services.hyprsunset.enable;
  message = ''
    The 'services.hyprsunset' module now supports freeform configuration.

    A new 'settings' option has been added to support the upstream configuration
    file format, allowing full access to all hyprsunset configuration options
    in a structured way.
  '';
}
