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

    lspServers = {
      go = {
        command = "gopls";
        args = [ "serve" ];
        extensionToLanguage = {
          ".go" = "go";
        };
      };
      typescript = {
        command = "typescript-language-server";
        args = [ "--stdio" ];
        extensionToLanguage = {
          ".ts" = "typescript";
          ".tsx" = "typescriptreact";
        };
      };
    };

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

    test "$(grep -o -- '--plugin-dir ' "$wrapperPath" | wc -l)" -eq 1
    pluginDir=$(grep -o -- '--plugin-dir /nix/store/[^ ]*' "$wrapperPath")
    pluginDir="''${pluginDir#--plugin-dir }"
    assertFileContent "$pluginDir/.claude-plugin/plugin.json" ${./expected-plugin-manifest.json}
    assertFileContent "$pluginDir/.mcp.json" ${./expected-mcp-plugin.json}
    assertFileContent "$pluginDir/.lsp.json" ${./expected-lsp-plugin.json}
  '';
}
