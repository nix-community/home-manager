{
  programs.crush = {
    enable = true;

    settings.mcp = {
      filesystem = {
        type = "stdio";
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "/tmp"
        ];
        timeout = 120;
      };
      github = {
        type = "http";
        url = "https://api.githubcopilot.com/mcp/";
        headers = {
          Authorization = "Bearer $(echo $GH_PAT)";
        };
      };
      streaming = {
        type = "sse";
        url = "https://example.com/mcp/sse";
        headers = {
          "API-Key" = "$(echo $API_KEY)";
        };
        disabled_tools = [ "some-tool" ];
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/crush/crush.json
    assertFileContent home-files/.config/crush/crush.json ${./expected-mcp-config.json}
  '';
}
