{
  config,
  lib,
  pkgs,
  ...
}:

{
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
              "enabled": false
            }
          },
        }
      '';

      expectedContent = builtins.toFile "expected.json" ''
        {
          "context_servers": {
            "custom-server": {
              "enabled": false,
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
              "command": "npx",
              "enabled": true,
              "env": {}
            }
          }
        }
      '';

      settingsPath = ".config/zed/settings.json";
      activationScript = pkgs.writeScript "activation" config.home.activation.zedSettingsActivation.data;
    in
    ''
      export HOME=$TMPDIR/hm-user

      # Simulate preexisting settings
      mkdir -p $HOME/.config/zed
      cat ${preexistingSettings} > $HOME/${settingsPath}

      # Run the activation script
      substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
      chmod +x $TMPDIR/activate
      $TMPDIR/activate

      # Validate the settings file exists and contains both MCP servers
      assertFileExists "$HOME/${settingsPath}"
      assertFileContent "$HOME/${settingsPath}" "${expectedContent}"
    '';
}
