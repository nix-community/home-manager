{ pkgs, ... }:
{
  programs.cursor = {
    enable = true;

    package = pkgs.writeScriptBin "code-cursor" "" // {
      pname = "code-cursor";
      version = "1.75.0";
    };

    profiles = {
      default.mcp = {
        servers = {
          Github = {
            url = "https://api.githubcopilot.com/mcp/";
          };
        };
      };
    };
  };

  nmt.script =
    let
      # In mutable profile mode (default with only `default` profile),
      # the file is written as `.immutable-mcp.json`.
      mcpOutputPath = ".cursor/.immutable-mcp.json";

      expectedMcp = pkgs.writeText "expected-mcp.json" ''
        {
          "servers": {
            "Github": {
              "url": "https://api.githubcopilot.com/mcp/"
            }
          }
        }
      '';
    in
    ''
      assertFileExists "home-files/${mcpOutputPath}"
      assertFileContent "home-files/${mcpOutputPath}" "${expectedMcp}"
    '';
}
