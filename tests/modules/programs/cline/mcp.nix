{
  programs.cline = {
    enable = true;
    package = null;
    mcpServers = {
      local-server = {
        command = "node";
        args = [ "/path/to/server.js" ];
        env.API_KEY = "your_api_key";
        disabled = false;
        autoApprove = [ ];
      };
      remote-server = {
        type = "streamableHttp";
        url = "https://example.com/mcp";
        headers.Authorization = "Bearer your-token";
        autoApprove = [ ];
      };
    };
  };

  nmt.script = ''
    assertFileContent home-files/.cline/data/settings/cline_mcp_settings.json \
      ${./mcp-expected.json}
  '';
}
