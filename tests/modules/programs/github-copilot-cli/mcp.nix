{ config, ... }:

{
  programs.github-copilot-cli = {
    enable = true;
    mcpServers = {
      playwright = {
        type = "local";
        command = "npx";
        args = [ "@playwright/mcp@latest" ];
        tools = [ "*" ];
      };
      context7 = {
        type = "http";
        url = "https://mcp.context7.com/mcp";
        tools = [ "*" ];
      };
    };
  };

  nmt.script =
    assert !(config.home.activation ? githubCopilotCliSettings);
    assert !(config.home.activation ? githubCopilotCliTrustedFolders);
    assert !(config.home.activation ? githubCopilotCliImmutableSettings);
    ''
      assertFileExists home-files/.copilot/mcp-config.json
      assertFileContent home-files/.copilot/mcp-config.json ${./expected-mcp-config.json}
      assertPathNotExists home-files/.copilot/config.json
      assertPathNotExists home-files/.copilot/settings.json
      assertFileNotRegex activate 'githubCopilotCliSettings|github-copilot-cli-settings.json'
    '';
}
