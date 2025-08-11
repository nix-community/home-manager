{ config, ... }:
{
  time = "2025-07-19T11:16:38+00:00";
  condition = config.programs.opencode.enable;
  message = ''
    The 'programs.opencode' module now supports global custom instructions.

    A new 'rules' option allows providing global custom instructions that
    will be written to '~/.config/opencode/AGENTS.md' for consistent
    behavior across all opencode sessions.
  '';
}
