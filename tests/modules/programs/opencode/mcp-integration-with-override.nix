{
  programs.mcp = {
    enable = true;
    servers = {
      everything = {
        type = "stdio";
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-everything"
        ];
      };
      context7 = {
        type = "sse";
        url = "https://mcp.context7.com/mcp";
        headers = {
          CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
        };
      };
    };
  };

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      theme = "opencode";
      model = "anthropic/claude-sonnet-4-20250514";
      # User's custom MCP settings should override generated ones
      mcp = {
        everything = {
          enabled = false; # Override to disable
          command = [ "custom-command" ];
          type = "local";
        };
        custom-server = {
          enabled = true;
          type = "remote";
          url = "https://example.com";
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/opencode.json
    assertFileContent home-files/.config/opencode/opencode.json \
      ${./mcp-integration-with-override.json}
  '';
}
