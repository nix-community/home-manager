{
  programs = {
    github-copilot-cli = {
      enable = true;
      enableMcpIntegration = true;
      # user-defined server takes precedence over the integrated one
      mcpServers.filesystem = {
        type = "local";
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "/tmp"
        ];
        tools = [ "*" ];
      };
    };
    mcp = {
      enable = true;
      servers = {
        filesystem = {
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
          ];
          env = {
            DATABASE_URL = "postgresql://user:pass@localhost:5432/db";
          };
        };
        fetch = {
          command = "mcp-server-fetch";
        };
        disabled-server = {
          command = "disabled-cmd";
          disabled = true;
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.copilot/mcp-config.json
    assertFileContent home-files/.copilot/mcp-config.json ${./expected-mcp-integration-config.json}
  '';
}
