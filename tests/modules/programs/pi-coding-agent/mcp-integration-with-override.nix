{ lib, ... }:

{
  imports = [ ./mcp-integration.nix ];

  programs.pi-coding-agent = {
    configDir = "/home/hm-user/.config/pi/agent";
    mcpServers = {
      everything = {
        command = "custom-server";
        enabled = false;
      };
      custom = {
        url = "https://custom.example.com/mcp";
      };
    };
  };

  nmt.script = lib.mkForce ''
    assertPathNotExists home-files/.pi/agent/mcp.json
    assertFileContent home-files/.config/pi/agent/mcp.json ${./mcp-integration-with-override.json}
  '';
}
