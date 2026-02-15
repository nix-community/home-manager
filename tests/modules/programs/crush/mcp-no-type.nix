{
  programs.crush = {
    enable = true;

    settings.mcp = {
      # Minimal MCP server with type defaulting to "stdio"
      filesystem = {
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "/tmp"
        ];
        timeout = 120;
      };
      # HTTP-based MCP server with explicit type
      github = {
        type = "http";
        url = "https://api.githubcopilot.com/mcp/";
        headers = {
          Authorization = "Bearer $(echo $GH_PAT)";
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/crush/crush.json
    assertFileContent home-files/.config/crush/crush.json ${./expected-mcp-no-type.json}
  '';
}
