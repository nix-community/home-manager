{ config, ... }:
{
  time = "2026-06-12T12:00:00+00:00";
  condition = config.programs.opencode.enable;
  message = ''
    The 'programs.opencode.settings' option now supports ordered Home Manager
    DAG entries in nested attribute sets.

    This allows order-sensitive OpenCode permission rules to be expressed with
    'lib.hm.dag.entryBefore' and 'lib.hm.dag.entryAfter'.
  '';
}
