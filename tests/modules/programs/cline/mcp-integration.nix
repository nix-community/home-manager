{
  programs = {
    cline = {
      enable = true;
      package = null;
      enableMcpIntegration = true;
      mcpServers.filesystem = {
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "/other-tmp"
        ];
      };
    };
    mcp = {
      enable = true;
      servers = {
        filesystem = {
          command = "npx";
          args = [ "/other-tmp" ];
        };
        github = {
          enabled = true;
          url = "https://api.githubcopilot.com/mcp/";
        };
        database = {
          command = "dbhub";
          env.DATABASE_URL = "postgresql://user:pass@localhost:5432/db";
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
    assertFileContent home-files/.cline/data/settings/cline_mcp_settings.json \
      ${./mcp-integration-expected.json}
  '';
}
