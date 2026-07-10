{
  programs = {
    claude-code = {
      package = null;
      enable = true;

      enableMcpIntegration = true;

      mcpServers = {
        github = {
          type = "http";
          url = "https://api.githubcopilot.com/mcp/";
          enabled = true;
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
    mcp = {
      enable = true;
      servers = {
        filesystem = {
          type = "stdio";
          command = "npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-filesystem"
            "/other-tmp"
          ];
        };
        database = {
          command = "npx";
          args = [
            "-y"
            "@bytebase/dbhub"
            "--dsn"
            "postgresql://user:pass@localhost:5432/db"
          ];
          env = {
            DATABASE_URL = "postgresql://user:pass@localhost:5432/db";
          };
        };
        customTransport = {
          type = "websocket";
          url = "wss://example.com/mcp";
          customOption = "value";
          timeout = 5000;
        };
        disabled-server = {
          command = "echo";
          args = [ "test" ];
          disabled = true;
        };
      };
    };
  };

  nmt.script = ''
    assertPathNotExists "$TESTED/home-path/bin/claude"

    pluginDir="$TESTED/home-files/.claude/skills/claude-code-home-manager"
    assertFileContent "$pluginDir/.claude-plugin/plugin.json" ${./expected-plugin-manifest.json}
    assertFileContent "$pluginDir/.mcp.json" ${./expected-mcp-integration-plugin.json}
    assertPathNotExists "$pluginDir/.lsp.json"

    settingsPath="$TESTED/home-files/.claude/settings.json"
    assertFileContent "$settingsPath" ${./expected-mcp-settings.json}
  '';
}
