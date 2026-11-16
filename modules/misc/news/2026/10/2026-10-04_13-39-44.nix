{ config, ... }:
{
  time = "2026-10-04T18:39:44+00:00";
  condition = config.programs.alistral.enable;
  message = ''
    The Alistral module now supports mutable settings through
    'programs.alistral.mutableSettings'.

    When enabled, Home Manager merges declared settings into a writable
    configuration file during activation. Declared values take precedence,
    while other settings and application-written credentials are preserved.
    Removing a declaration does not remove its saved value. This option
    defaults to false, so settings remain read-only unless you opt in.

    Both modes now use 'xdg.configHome' on Linux. The macOS configuration
    location is unchanged.
  '';
}
