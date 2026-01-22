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
        headers = {
          CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
        };
      };
      disabled-server = {
        command = "echo";
        args = [ "test" ];
        disabled = true;
      };
    };
  };

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/opencode.json
    assertFileContent home-files/.config/opencode/opencode.json \
      ${./mcp-integration.json}
  '';
}
