{
  pkgs,
  lib,
  options,
  ...
}:

let
  renamedWarning =
    name:
    "The option `programs.gemini-cli.${name}' defined in ${
      lib.showFiles (
        lib.getAttrFromPath [
          "programs"
          "gemini-cli"
          name
          "files"
        ] options
      )
    } has been renamed to `programs.antigravity-cli.${name}'.";
in
{
  programs = {
    gemini-cli = {
      enable = true;
      package = pkgs.writeShellScriptBin "gemini-cli" "";
      enableMcpIntegration = lib.mkIf true true;
      settings = {
        theme = "Default";
        vimMode = true;
        mcpServers = {
          github = {
            url = "https://api.githubcopilot.com/mcp/";
            env = {
              url = "https://token.example/env";
            };
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
          };
        };
      };
    };
  };
  test.asserts.warnings.expected = map renamedWarning [
    "settings"
    "package"
    "enableMcpIntegration"
    "enable"
  ];

  nmt.script = ''
    assertFileExists home-files/.gemini/settings.json
    assertFileRegex home-files/.gemini/settings.json '"github"'
    assertFileRegex home-files/.gemini/settings.json '"url"'
    assertFileRegex home-files/.gemini/settings.json 'https://token.example/env'
    assertFileRegex home-files/.gemini/settings.json '"filesystem"'
    assertFileRegex home-files/.gemini/settings.json '"database"'
    assertFileNotRegex home-files/.gemini/settings.json '"other-tmp"'
  '';
}
