{
  programs.cursor-agent = {
    enable = true;
    package = null;

    mcpServers = {
      context7 = {
        type = "http";
        url = "https://mcp.context7.com/mcp";
      };
      filesystem = {
        type = "stdio";
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "/tmp"
        ];
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.cursor/mcp.json
    assertFileContent home-files/.cursor/mcp.json \
      ${./expected-mcp.json}
  '';
}
