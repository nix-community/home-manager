_: {
  time = "2026-04-17T15:06:14+00:00";
  condition = true;
  message = ''
    A new module is available: 'programs.github-copilot-cli'.

    GitHub Copilot CLI brings the agentic Copilot coding experience to the
    terminal. The module manages the `~/.copilot/config.json` settings file
    (model, theme, trusted folders, hooks, feature flags, etc.) and the
    `~/.copilot/mcp-config.json` MCP server registry. Setting
    `enableMcpIntegration = true` reuses servers defined under
    `programs.mcp.servers`, with `programs.github-copilot-cli.mcpServers`
    taking precedence.
  '';
}
