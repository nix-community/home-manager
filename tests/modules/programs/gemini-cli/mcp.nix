{
  programs = {
    gemini-cli = {
      enable = true;
      enableMcpIntegration = true;
      settings = {
        theme = "Default";
        vimMode = true;
        mcpServers = {
          github = {
            url = "https://api.githubcopilot.com/mcp/";
          };
          filesystem = {
            command = "npx";
            args = [
              "-y"
              "@modelcontextprotocol/server-filesystem"
              "/tmp"
            ];
          };
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
      };
    };
  };
  nmt.script = ''
    assertFileExists home-files/.gemini/settings.json
    assertFileRegex home-files/.gemini/settings.json '"github"'
    assertFileRegex home-files/.gemini/settings.json '"filesystem"'
    assertFileRegex home-files/.gemini/settings.json '"database"'
    assertFileNotRegex home-files/.gemini/settings.json '"other-tmp"'
  '';
}
