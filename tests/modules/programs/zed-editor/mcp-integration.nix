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
      context7 = {
        url = "https://mcp.context7.com/mcp";
        headers = {
          CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
        };
      };
      disabled-server = {
        command = "echo";
        args = [ "test" ];
        disabled = true;
      };
    };
  };

  programs.zed-editor = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    enableMcpIntegration = true;
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script =
    let
      expectedContent = builtins.toFile "expected.json" ''
        {
          "context_servers": {
            "context7": {
              "headers": {
                "CONTEXT7_API_KEY": "{env:CONTEXT7_API_KEY}"
              },
              "type": "http",
              "url": "https://mcp.context7.com/mcp"
            },
            "disabled-server": {
              "args": [
                "test"
              ],
              "command": "echo",
              "enabled": false,
              "type": "stdio"
            },
            "everything": {
              "args": [
                "-y",
                "@modelcontextprotocol/server-everything"
              ],
              "command": "npx",
              "type": "stdio"
            }
          }
        }
      '';

      settingsPath = ".config/zed/settings.json";
    in
    config.lib.test.runMutableConfigTest {
      expected.${settingsPath} = expectedContent;
    };
}
