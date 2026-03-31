{ config, ... }:
{
  time = "2026-03-31T17:22:36+00:00";
  condition = config.programs.gemini-cli.enable;
  message = ''
    The `programs.gemini-cli.mcpServers` and `programs.gemini-cli.enableMcpIntegration`
    options have been added to support configuring the Gemini CLI MCP servers. Another
    `programs.gemini-cli.skills` option has been added to manage the agent skills.

    The MCP servers introduced due to `programs.gemini-cli.enableMcpIntegration` will
    be ignored if one with same name exists in `programs.gemini-cli.mcpServers`.

    The `programs.gemini-cli.settings.mcpServers` should be avoided because it will not
    be checked for duplicates from the MCP integration
  '';
}
