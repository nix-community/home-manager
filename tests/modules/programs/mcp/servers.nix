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
        env = {
          DEBUG = "1";
        };
        timeout = 5000;
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
        timeout = 10000;
      };

      disabled = {
        type = "stdio";
        command = "echo";
        enabled = false;
      };
    };
  };
  nmt.script = ''
    assertFileExists home-files/.config/mcp/mcp.json
    assertFileContent home-files/.config/mcp/mcp.json \
      ${./mcp.json}
  '';
}
