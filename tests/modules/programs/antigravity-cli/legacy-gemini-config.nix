{ pkgs, ... }:

{
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "antigravity-cli" "";
    useLegacyGeminiConfig = true;
    settings.theme = "Default";
    mcpServers.github.serverUrl = "https://api.githubcopilot.com/mcp/";
    commands.review = {
      prompt = "Review current changes.";
      description = "Reviews current changes.";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.gemini/settings.json
    assertFileExists home-files/.gemini/commands/review.toml
    assertFileRegex home-files/.gemini/settings.json '"github"'
    assertPathNotExists home-files/.gemini/antigravity-cli/settings.json
    assertPathNotExists home-files/.gemini/config/mcp_config.json
    assertPathNotExists home-files/.gemini/antigravity-cli/skills/review/SKILL.md
  '';
}
