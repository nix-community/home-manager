{ pkgs, ... }:
{
  programs.antigravity-cli = {
    enable = true;
    mutableSettings = true;
    package = pkgs.writeShellScriptBin "gemini-cli" "";
    useLegacyGeminiConfig = false;
    settings.theme = "Default";
  };
  test.asserts.assertions.expected = [
    "programs.antigravity-cli.mutableSettings only supports native Antigravity CLI configuration, not legacy Gemini CLI configuration."
  ];
}
