{
  programs.mcp = {
    enable = true;
    servers = {
      everything = {
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-everything"
        ];
      };
      context7 = {
        url = "https://mcp.context7.com/mcp";
        headers.CONTEXT7_API_KEY = "secret";
      };
      disabled-server = {
        command = "echo";
        enabled = false;
      };
    };
  };

  programs.warp-terminal = {
    enable = true;
    package = null;
    enableMcpIntegration = true;
    mcpServers.context7.url = "http://localhost:4000/mcp/stream";
  };

  nmt.script = ''
    assertFileContent home-files/.warp/.mcp.json ${./mcp-integration.json}
    assertPathNotExists home-files/.config/warp-terminal/settings.toml
  '';
}
