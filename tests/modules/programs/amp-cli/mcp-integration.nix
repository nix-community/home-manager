{
  programs = {
    amp-cli = {
      enable = true;

      enableMcpIntegration = true;

      mcpServers = {
        playwright = {
          command = "npx";
          args = [
            "-y"
            "@playwright/mcp@latest"
            "--headless"
          ];
        };
      };
    };
    mcp = {
      enable = true;
      servers = {
        linear = {
          url = "https://mcp.linear.app/sse";
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
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/amp/settings.json
    assertFileContent home-files/.config/amp/settings.json ${./expected-mcp-integration-settings.json}
  '';
}
