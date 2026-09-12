{ config, ... }:
{
  time = "2026-08-03T19:35:00+00:00";
  condition = config.programs.gimp.enable;
  message = ''
    A new module is available: {option}`programs.gimp`.

    This module installs and configures the GIMP image editor, including
    `gimprc` and `shortcutsrc` settings, controllers, and content
    directories (brushes, patterns, scripts, plug-ins, and more).
  '';
}
