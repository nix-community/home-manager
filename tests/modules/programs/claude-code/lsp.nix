{ config, ... }:

{
  programs.claude-code = {
    package = config.lib.test.mkStubPackage {
      name = "claude-code";
      version = "2.1.197";
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
  };

  nmt.script = ''
    assertPathNotExists "$TESTED/home-path/bin/.claude-wrapped"

    pluginDir="$TESTED/home-files/.claude/skills/claude-code-home-manager"
    assertFileContent "$pluginDir/.claude-plugin/plugin.json" ${./expected-plugin-manifest.json}
    assertFileContent "$pluginDir/.lsp.json" ${./expected-lsp-plugin.json}
    assertPathNotExists "$pluginDir/.mcp.json"
  '';
}
