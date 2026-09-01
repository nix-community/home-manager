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
        env.NPM_TOKEN.file = "/run/secrets/npm-token";
      };
      context7 = {
        url = "https://mcp.context7.com/mcp";
        headers.CONTEXT7_API_KEY = "$CONTEXT7_API_KEY";
      };
      disabled-server = {
        command = "echo";
        args = [ "test" ];
        enabled = false;
      };
      filesystem = {
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "/other-tmp"
        ];
      };
    };
  };

  programs.crush = {
    enable = true;
    package = null;
    enableMcpIntegration = true;

    settings.mcp.filesystem = {
      type = "stdio";
      command = "npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-filesystem"
        "/tmp"
      ];
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/crush/crush.json ${./mcp-integration.json}
  '';
}
