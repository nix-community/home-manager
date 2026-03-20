{ config, ... }:
{
  time = "2026-03-09T18:49:35+00:00";
  condition = config.programs.zed-editor.enable;
  message = ''
    The `programs.zed-editor` module now supports MCP integration via
    `programs.zed-editor.enableMcpIntegration`.

    When enabled, shared servers from `programs.mcp.servers` are merged
    into `programs.zed-editor.userSettings.context_servers`, with
    settings-based values taking precedence.
  '';
}
