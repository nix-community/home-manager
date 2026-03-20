{
  programs.mcp = {
    enable = true;
    servers = { };
  };
  nmt.script = ''
    assertPathNotExists home-files/.config/mcp/mcp.json
  '';
}
