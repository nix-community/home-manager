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
      disabled-server = {
        type = "stdio";
        command = "echo";
        args = [ "test" ];
        disabled = true;
      };
    };
  };

  programs.codex = {
    enable = true;
    enableMcpIntegration = true;
  };

  nmt.script = ''
    assertFileExists home-files/.codex/config.toml
    assertFileContent home-files/.codex/config.toml \
      ${./mcp-integration.toml}
  '';
}
