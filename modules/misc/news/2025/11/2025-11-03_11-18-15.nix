{
  time = "2025-11-03T10:18:15+00:00";
  condition = true;
  message = ''
    A new module 'programs.mcp' is now available for managing Model
    Context Protocol (MCP) server configurations.

    The 'programs.mcp.servers' option allows you to define MCP servers
    in a central location. These configurations can be automatically
    integrated into applications that support MCP.

    Two modules now support MCP integration:

    - 'programs.opencode.enableMcpIntegration': Integrates MCP servers
      into OpenCode's configuration.

    - 'programs.vscode.profiles.<name>.enableMcpIntegration': Integrates
      MCP servers into VSCode profiles.

    When integration is enabled, servers from 'programs.mcp.servers' are
    merged with application-specific MCP settings, with the latter taking
    precedence. This allows you to define MCP servers once and reuse them
    across multiple applications.
  '';
}
