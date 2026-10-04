{ config, ... }:
{
  time = "2026-10-05T01:21:09+00:00";
  condition = config.programs.vicinae.enable;
  message = ''
    Vicinae now supports `programs.vicinae.enableMutableConfig` to load
    declarative settings through a separate read-only override file, leaving
    its user settings writable. The option is disabled by default and
    requires Vicinae 0.20.6 or later.
  '';
}
