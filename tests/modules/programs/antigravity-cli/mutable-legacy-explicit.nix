_: {
  programs.antigravity-cli = {
    enable = true;
    mutableSettings = true;
    package = null;
    useLegacyGeminiConfig = true;
    settings.theme = "Default";
  };
  test.asserts.assertions.expected = [
    "programs.antigravity-cli.mutableSettings only supports native Antigravity CLI configuration, not legacy Gemini CLI configuration."
  ];
}
