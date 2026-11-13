{ config, ... }:
{
  time = "2026-10-05T01:21:09+00:00";
  condition = config.programs.vicinae.enable;
  message = ''
    Vicinae now supports `programs.vicinae.mutableSettings` to load
    declarative settings through a separate read-only override file, leaving
    its user settings writable. The option is disabled by default and
    requires Vicinae 0.20.6 or later.

    The module now requires Vicinae 0.17.0 or later. Legacy JSON themes,
    the vicinae.json configuration file, and the USE_LAYER_SHELL environment
    variable are no longer supported. Replace programs.vicinae.useLayerShell
    with programs.vicinae.settings.launcher_window.layer_shell.enabled.
  '';
}
