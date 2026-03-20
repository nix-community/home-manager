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
    };
  };

  programs.codex = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      model = "gpt-5-codex";
      mcp_servers = {
        custom-server = {
          url = "http://localhost:3000/mcp";
          enabled = true;
          enabled_tools = [
            "open"
            "screenshot"
          ];
        };
        everything = {
          command = "final-command";
          enabled = false;
          tool_timeout_sec = 45;
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.codex/config.toml
    assertFileContent home-files/.codex/config.toml \
      ${./mcp-integration-with-override.toml}
  '';
}
