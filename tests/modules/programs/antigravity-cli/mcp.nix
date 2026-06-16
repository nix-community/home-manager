{ pkgs, ... }:

{
  programs = {
    antigravity-cli = {
      enable = true;
      package = pkgs.writeShellScriptBin "antigravity-cli" "";
      enableMcpIntegration = true;
      settings = {
        colorScheme = "terminal";
        toolPermission = "request-review";
      };
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
            "--dsn"
            "postgresql://user:pass@localhost:5432/db"
          ];
          env = {
            DATABASE_URL = "postgresql://user:pass@localhost:5432/db";
            url = "https://token.example/env";
          };
        };
        remote-server = {
          url = "https://remote.example/mcp";
          headers = {
            "Authorization" = "Bearer token";
          };
        };
      };
    };
  };
  nmt.script = ''
    assertFileExists home-files/.gemini/config/mcp_config.json
    assertFileRegex home-files/.gemini/config/mcp_config.json '"github"'
    assertFileRegex home-files/.gemini/config/mcp_config.json '"serverUrl"'
    assertFileRegex home-files/.gemini/config/mcp_config.json '"url"'
    assertFileRegex home-files/.gemini/config/mcp_config.json 'https://token.example/env'
    assertFileRegex home-files/.gemini/config/mcp_config.json '"filesystem"'
    assertFileRegex home-files/.gemini/config/mcp_config.json '"database"'
    assertFileNotRegex home-files/.gemini/config/mcp_config.json '"other-tmp"'
    assertFileRegex home-files/.gemini/config/mcp_config.json '"remote-server"'
    assertFileRegex home-files/.gemini/config/mcp_config.json '"serverUrl": "https://remote.example/mcp"'
    assertFileRegex home-files/.gemini/config/mcp_config.json '"type": "http"'
    assertFileNotRegex home-files/.gemini/config/mcp_config.json '"command": null'
    assertFileNotRegex home-files/.gemini/config/mcp_config.json '"env": {}'
  '';
}
