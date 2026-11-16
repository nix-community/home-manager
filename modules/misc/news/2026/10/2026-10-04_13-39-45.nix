{ config, ... }:
{
  time = "2026-10-04T18:39:45+00:00";
  condition = config.programs.andcli.enable;
  message = ''
    The andcli module now supports mutable settings through
    'programs.andcli.mutableSettings'.

    When enabled, Home Manager merges declared settings into a writable
    configuration file during activation. Declared values take precedence,
    while other settings are preserved. Removing a declaration does not
    remove its saved value. Comments and formatting are not preserved. This
    option defaults to false, so settings remain read-only unless you opt
    in.
  '';
}
