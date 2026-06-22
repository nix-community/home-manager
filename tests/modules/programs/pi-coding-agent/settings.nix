{
  programs.pi-coding-agent = {
    enable = true;
    settings = {
      defaultProvider = "anthropic";
      defaultModel = "claude-sonnet-4-20250514";
      defaultThinkingLevel = "medium";
      theme = "dark";
      compaction = {
        enabled = true;
        reserveTokens = 16384;
        keepRecentTokens = 20000;
      };
      retry = {
        enabled = true;
        maxRetries = 3;
      };
      enabledModels = [
        "claude-*"
        "gpt-4o"
      ];
    };
  };
  nmt.script = ''
    assertFileExists home-files/.pi/agent/settings.json
    assertFileContent home-files/.pi/agent/settings.json \
      ${./settings.json}
  '';
}
