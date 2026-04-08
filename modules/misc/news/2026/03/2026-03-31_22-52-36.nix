{ config, ... }:
{
  time = "2026-03-31T17:22:36+00:00";
  condition = config.programs.gemini-cli.enable;
  message = ''
    The `programs.gemini-cli.enableMcpIntegration` and `programs.gemini-cli.skills`
    options have been added to support configuring the Gemini CLI MCP servers and
    managing agent skills.

    The global MCP servers from `programs.mcp.servers` are now integrated directly into
    `programs.gemini-cli.settings.mcpServers` when `enableMcpIntegration` is enabled.
    Any servers explicitly defined in `programs.gemini-cli.settings.mcpServers` will
    take precedence over those from the global MCP configuration.
  '';
}
