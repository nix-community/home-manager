{ lib, ... }:

{
  imports = [ ./mcp-integration.nix ];

  programs.pi-coding-agent.enableMcpIntegration = lib.mkForce false;

  nmt.script = lib.mkForce ''
    assertPathNotExists home-files/.pi/agent/mcp.json
  '';
}
