{
  config,
  lib,
  ...
}:

{
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
      server-no-args = {
        command = "echo";
      };
    };
  };

  programs.zed-editor = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    enableMcpIntegration = true;
    userSettings = {
      context_servers = {
        custom-server = {
          url = "https://custom.example.com/mcp";
          headers = {
            Authorization = "Bearer token";
          };
        };
      };
    };
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script =
    let
      preexistingSettings = builtins.toFile "preexisting.json" ''
        {
          "context_servers": {
            "custom-server": {
            }
          },
        }
      '';

      expectedContent = builtins.toFile "expected.json" ''
        {
          "context_servers": {
            "custom-server": {
              "headers": {
                "Authorization": "Bearer token"
              },
              "url": "https://custom.example.com/mcp"
            },
            "everything": {
              "args": [
                "-y",
                "@modelcontextprotocol/server-everything"
              ],
              "command": "npx"
            },
            "server-no-args": {
              "args": [],
              "command": "echo"
            }
          }
        }
      '';

      settingsPath = ".config/zed/settings.json";
    in
    config.lib.test.runMutableConfigTest {
      files.${settingsPath} = preexistingSettings;
      expected.${settingsPath} = expectedContent;
    };
}
