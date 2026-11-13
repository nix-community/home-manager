{ config, ... }:
{
  time = "2026-10-04T18:39:30+00:00";
  condition = config.programs.claude-code.enable;
  message = ''
    The Claude Code module now supports mutable settings through
    'programs.claude-code.mutableSettings'.

    When enabled, Home Manager merges declared settings and known
    marketplaces into writable files during activation. Declared values take
    precedence, while other settings and application-owned marketplace
    metadata are preserved. Removing a declaration does not remove its saved
    value. This option defaults to false, so settings remain read-only
    unless you opt in.
  '';
}
