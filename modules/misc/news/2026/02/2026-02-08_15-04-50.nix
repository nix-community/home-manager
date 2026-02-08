{ config, ... }:
{
  time = "2026-02-08T21:04:50+00:00";
  condition = config.programs.codex.enable;
  message = ''
    The `programs.codex` module now supports MCP integration via
    `programs.codex.enableMcpIntegration`.

    When enabled, shared servers from `programs.mcp.servers` are merged
    into `programs.codex.settings.mcp_servers`, with settings-based values
    taking precedence.
  '';
}
