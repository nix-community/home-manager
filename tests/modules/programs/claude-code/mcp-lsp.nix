{ config, ... }:

{
  programs.claude-code = {
    package = config.lib.test.mkStubPackage {
      name = "claude-code";
      version = "2.1.76";
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

    plugins = [ ./test-plugin ];
  };

  test.asserts.warnings.expected = [
    ''
      `programs.claude-code.package` version 2.1.76
      uses the legacy `--plugin-dir` wrapper. Strict-parser subcommands such
      as `claude rc` may reject managed MCP, LSP, or plugin arguments. Upgrade
      Claude Code to version 2.1.157 or later to use persistent personal
      plugins instead.
    ''
  ];

  nmt.script = ''
    wrapperPath="$TESTED/home-path/bin/claude"
    normalizedWrapper=$(normalizeStorePaths "$wrapperPath")
    assertFileContent "$normalizedWrapper" ${./expected-mcp-wrapper}

    test "$(grep -o -- '--plugin-dir ' "$wrapperPath" | wc -l)" -eq 2
    pluginDir=$(grep -o -- '--plugin-dir /nix/store/[^ ]*' "$wrapperPath" | head -1)
    pluginDir="''${pluginDir#--plugin-dir }"
    assertFileContent "$pluginDir/.claude-plugin/plugin.json" ${./expected-plugin-manifest.json}
    assertFileContent "$pluginDir/.mcp.json" ${./expected-mcp-plugin.json}
    assertFileContent "$pluginDir/.lsp.json" ${./expected-lsp-plugin.json}
    assertPathNotExists "$TESTED/home-files/.claude/skills/claude-code-home-manager"
    assertPathNotExists "$TESTED/home-files/.claude/skills/test-plugin"
  '';
}
