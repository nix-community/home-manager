{
  imports = [ ./mcp.nix ];

  programs.mcp = {
    enable = false;
    servers.unused.command = "unused-server";
  };
  programs.pi-coding-agent.enableMcpIntegration = true;
}
