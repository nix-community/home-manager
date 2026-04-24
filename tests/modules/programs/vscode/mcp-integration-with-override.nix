package:

{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.programs.vscode;
  willUseIfd = package.pname != "vscode";

  mcpFilePath =
    name:
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/${cfg.nameShort}/User/${
        lib.optionalString (name != "default") "profiles/${name}/"
      }mcp.json"
    else
      ".config/${cfg.nameShort}/User/${
        lib.optionalString (name != "default") "profiles/${name}/"
      }mcp.json";

in

lib.mkIf (willUseIfd -> config.test.enableLegacyIfd) {
  programs.mcp = {
    enable = true;
    servers = {
      everything = {
        type = "stdio";
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-everything"
        ];
      };
      context7 = {
        type = "http";
        url = "https://mcp.context7.com/mcp";
        headers = {
          CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
        };
      };
    };
  };

  programs.vscode = {
    enable = true;
    inherit package;
    profiles = {
      default = {
        enableMcpIntegration = true;
        # User MCP settings should override generated ones
        userMcp = {
          servers = {
            everything = {
              command = "custom-npx";
              args = [
                "-y"
                "@modelcontextprotocol/server-everything"
              ];
              enabled = false;
              type = "stdio";
            };
            CustomServer = {
              type = "http";
              url = "https://example.com/mcp";
            };
          };
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists "home-files/${mcpFilePath "default"}"
    assertFileContent "home-files/${mcpFilePath "default"}" ${./mcp-integration-with-override.json}
  '';
}
