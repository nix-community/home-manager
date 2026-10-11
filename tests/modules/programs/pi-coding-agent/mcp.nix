{
  programs.pi-coding-agent = {
    enable = true;
    mcpServers = {
      filesystem = {
        command = "npx";
        args = [ "@modelcontextprotocol/server-filesystem" ];
        cwd = "~/projects";
        env.API_KEY = "\${API_KEY}";
      };
      docs = {
        url = "https://example.com/mcp";
        headers.Authorization = "Bearer \${DOCS_TOKEN}";
        oauth.clientId = "pi-client";
        exposure = "deferred";
        toolExposure.search = "direct";
      };
      disabled = {
        command = "disabled-server";
        enabled = false;
      };
    };
  };

  nmt.script = ''
    assertFileContent home-files/.pi/agent/mcp.json ${./mcp.json}
  '';
}
