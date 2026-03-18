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
    wrapperPath="$TESTED/home-path/bin/claude"
    normalizedWrapper=$(normalizeStorePaths "$wrapperPath")
    assertFileContent "$normalizedWrapper" ${./expected-mcp-wrapper}

    pluginDir=$(grep -o -- '--plugin-dir /nix/store/[^ ]*' "$wrapperPath")
    pluginDir="''${pluginDir#--plugin-dir }"
    assertFileContent "$pluginDir/.claude-plugin/plugin.json" ${./expected-plugin-manifest.json}
    assertFileContent "$pluginDir/.mcp.json" ${./expected-mcp-plugin.json}
    assertPathNotExists "$pluginDir/.lsp.json"
  '';
}
