{
  programs.mcp = {
    enable = true;
    servers = {
      everything = {
        command = "npx";
        args = [ "@modelcontextprotocol/server-everything" ];
      };
      docs = {
        url = "https://example.com/mcp";
        headers.Accept = "application/json";
      };
      disabled = {
        command = "disabled-server";
        disabled = true;
      };
    };
  };

  programs.pi-coding-agent = {
    enable = true;
    enableMcpIntegration = true;
  };

  nmt.script = ''
    assertFileContent home-files/.pi/agent/mcp.json ${./mcp-integration.json}
  '';
}
