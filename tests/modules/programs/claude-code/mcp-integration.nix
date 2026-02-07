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
          enabled = false;
        };
      };
    };
  };

  nmt.script = ''
    normalizedWrapper=$(normalizeStorePaths home-path/bin/claude)
    assertFileContent $normalizedWrapper ${./expected-mcp-wrapper}
  '';
}
