{ config, ... }:
{
  time = "2026-10-04T18:39:46+00:00";
  condition = config.programs.algia.enable;
  message = ''
    The Algia module now supports mutable settings through
    'programs.algia.mutableSettings'.

    When enabled, Home Manager merges declared settings into a writable
    configuration file during activation. Declared values take precedence,
    while other settings and application-written credentials are preserved.
    Entries in 'programs.algia.settings.followList' are combined and
    deduplicated. Removing a declaration does not remove its saved value.
    This option defaults to false, so settings remain read-only unless you
    opt in.
  '';
}
