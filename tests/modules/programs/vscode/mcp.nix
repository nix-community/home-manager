{ pkgs, lib, ... }:

let

  mcpFilePath =
    name:
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/Code/User/${
        lib.optionalString (name != "default") "profiles/${name}/"
      }mcp.json"
    else
      ".config/Code/User/${lib.optionalString (name != "default") "profiles/${name}/"}mcp.json";

  content = ''
    {
      "servers": {
        "Github": {
          "url": "https://api.githubcopilot.com/mcp/"
        }
      }
    }
  '';

  mcp = {
    servers = {
      Github = {
        url = "https://api.githubcopilot.com/mcp/";
      };
    };
  };

  customMcpPath = pkgs.writeText "custom.json" content;

  expectedMcp = pkgs.writeText "mcp-expected.json" ''
    {
      "servers": {
        "Github": {
          "url": "https://api.githubcopilot.com/mcp/"
        }
      }
    }
  '';

  expectedCustomMcp = pkgs.writeText "custom-expected.json" content;

in
{
  programs.vscode = {
    enable = true;
    package = pkgs.writeScriptBin "vscode" "" // {
      pname = "vscode";
      version = "1.75.0";
    };
    profiles = {
      default.userMcp = mcp;
      test.userMcp = mcp;
      custom.userMcp = customMcpPath;
    };
  };

  nmt.script = ''
    assertFileExists "home-files/${mcpFilePath "default"}"
    assertFileContent "home-files/${mcpFilePath "default"}" "${expectedMcp}"

    assertFileExists "home-files/${mcpFilePath "test"}"
    assertFileContent "home-files/${mcpFilePath "test"}" "${expectedMcp}"

    assertFileExists "home-files/${mcpFilePath "custom"}"
    assertFileContent "home-files/${mcpFilePath "custom"}" "${expectedCustomMcp}"
  '';
}
