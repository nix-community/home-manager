{ config, ... }:

{
  programs = {
    claude-code = {
      package = config.lib.test.mkStubPackage {
        name = "claude-code";
        buildScript = ''
          mkdir -p $out/bin
          touch $out/bin/claude
          chmod 755 $out/bin/claude
        '';
      };
      enable = true;

      enableMcpIntegration = true;

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
        context7 = {
          type = "http";
          url = "https://mcp.context7.com/mcp";
          headers = {
            API_KEY = "secret";
          };
        };
        atlassian = {
          type = "sse";
          url = "https://api-private.atlassian.com/mcp";
          headers = {
            Authorization = "Bearer token";
          };
        };
        disabled = {
          type = "stdio";
          command = "echo";
          disabled = true;
        };
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
    assertFileRegex "$pluginDir/.mcp.json" '"github"'
    assertFileRegex "$pluginDir/.mcp.json" '"context7"'
    assertFileRegex "$pluginDir/.mcp.json" '"atlassian"'
    assertFileRegex "$pluginDir/.mcp.json" '"/tmp"'
    (! grep -q -- '/other-tmp' "$pluginDir/.mcp.json")
    (! grep -q -- '"disabled"' "$pluginDir/.mcp.json")
    assertPathNotExists "$pluginDir/.lsp.json"
  '';
}
