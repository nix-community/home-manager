{ config, ... }:

{
  programs.claude-code = {
    package = config.lib.test.mkStubPackage {
      name = "claude-code";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/claude
        chmod 755 $out/bin/claude
      '';
    };
    enable = true;

    mcpServers = {
      github = {
        type = "http";
        url = "https://api.githubcopilot.com/mcp/";
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
      database = {
        type = "stdio";
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
    };
  };

  nmt.script = ''
    normalizedWrapper=$(normalizeStorePaths home-path/bin/claude)
    assertFileContent $normalizedWrapper ${./expected-mcp-wrapper}
  '';
}
