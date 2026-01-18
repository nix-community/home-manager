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
        type = "http";
        url = "https://mcp.context7.com/mcp";
        headers = {
          CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
        };
      };
      atlassian = {
        type = "sse";
        url = "https://api-private.atlassian.com/mcp";
        headers = {
          Authorization = "Bearer token";
        };
        timeout = 8000;
      };
      disabled = {
        type = "stdio";
        command = "echo";
        enabled = false;
      };
    };
  };

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/config.json
    assertFileContent home-files/.config/opencode/config.json \
      ${./mcp-integration.json}
  '';
}
