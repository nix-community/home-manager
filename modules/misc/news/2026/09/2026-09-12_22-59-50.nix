{ config, ... }:
{
  time = "2026-09-13T03:59:50+00:00";
  condition = config.programs.worktrunk.enable;
  message = ''
    Worktrunk now supports Bash, Zsh, Fish, and Nushell integrations.
    Enable Claude Code integration with
    'programs.worktrunk.claudeCodeIntegration.enable = true'.
  '';
}
