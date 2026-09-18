{
  programs.amp-cli = {
    enable = true;

    mcpServers = {
      playwright = {
        command = "npx";
        args = [
          "-y"
          "@playwright/mcp@latest"
          "--headless"
        ];
      };
      linear = {
        url = "https://mcp.linear.app/sse";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/amp/settings.json
    assertFileContent home-files/.config/amp/settings.json ${./expected-mcp-settings.json}
  '';
}
