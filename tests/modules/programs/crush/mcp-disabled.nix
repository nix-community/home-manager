{
  programs.crush = {
    enable = true;

    settings.mcp = {
      # MCP server with disabled explicitly set to true
      disabled-server = {
        type = "stdio";
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "/tmp"
        ];
        disabled = true;
        timeout = 120;
      };
      # MCP server with disabled explicitly set to false (default)
      enabled-server = {
        type = "http";
        url = "https://api.example.com/mcp";
        headers = {
          Authorization = "Bearer test";
        };
        disabled = false;
      };
      # MCP server with no disabled setting at all
      unknown-server = {
        command = "test-server";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/crush/crush.json
    assertFileContent home-files/.config/crush/crush.json ${./expected-mcp-disabled.json}
  '';
}
