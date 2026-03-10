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
              "enabled": true,
              "headers": {
                "CONTEXT7_API_KEY": "{env:CONTEXT7_API_KEY}"
              },
              "url": "https://mcp.context7.com/mcp"
            },
            "disabled-server": {
              "args": [
                "test"
              ],
              "command": "echo",
              "enabled": false
            },
            "everything": {
              "args": [
                "-y",
                "@modelcontextprotocol/server-everything"
              ],
              "command": "npx",
              "enabled": true
            }
          }
        }
      '';

      settingsPath = ".config/zed/settings.json";
      activationScript = pkgs.writeScript "activation" config.home.activation.zedSettingsActivation.data;
    in
    ''
      export HOME=$TMPDIR/hm-user

      # Run the activation script
      substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
      chmod +x $TMPDIR/activate
      $TMPDIR/activate

      # Validate the settings file exists and contains MCP servers
      assertFileExists "$HOME/${settingsPath}"
      assertFileContent "$HOME/${settingsPath}" "${expectedContent}"
    '';
}
