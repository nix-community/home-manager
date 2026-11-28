_: {
  programs.antigravity-cli = {
    enable = true;
    package = null;
    useLegacyGeminiConfig = true;
    agents.code-reviewer = ./agents/code-reviewer/agent.md;
  };

  test.asserts.assertions.expected = [
    "programs.antigravity-cli.agents only supports native Antigravity CLI configuration, not legacy Gemini CLI configuration."
  ];
}
