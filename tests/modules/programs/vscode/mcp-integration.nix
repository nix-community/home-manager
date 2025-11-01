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
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-everything"
        ];
      };
      context7 = {
        url = "https://mcp.context7.com/mcp";
        headers = {
          CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
        };
      };
      disabled-server = {
        command = "echo";
        disabled = true;
      };
    };
  };

  programs.vscode = {
    enable = true;
    inherit package;
    profiles = {
      default.enableMcpIntegration = true;
      test.userMcp = {
        servers = {
          Github = {
            url = "https://api.githubcopilot.com/mcp/";
          };
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists "home-files/${mcpFilePath "default"}"
    assertFileContent "home-files/${mcpFilePath "default"}" ${./mcp-integration-default.json}

    assertFileExists "home-files/${mcpFilePath "test"}"
    assertFileContent "home-files/${mcpFilePath "test"}" ${./mcp-integration-test.json}
  '';
}
