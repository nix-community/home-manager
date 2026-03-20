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
        serverUrl = "https://mcp.context7.com/mcp";
        headers = {
          CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
        };
      };
    };
  };
  nmt.script = ''
    assertFileExists home-files/.config/mcp/mcp.json
    assertFileContent home-files/.config/mcp/mcp.json \
      ${./mcp.json}
  '';
}
