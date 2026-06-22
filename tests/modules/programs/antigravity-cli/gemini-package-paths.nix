{ pkgs, ... }:

{
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "gemini-cli" "";
    settings.theme = "Default";
    commands.review = {
      prompt = "Review current changes.";
      description = "Reviews current changes.";
    };
    skills.audit = ''
      ---
      name: audit
      description: Audit code changes.
      ---

      Audit code changes.
    '';
    policies.commands.rule = [
      {
        toolName = "run_shell_command";
        commandPrefix = "git ";
        decision = "ask_user";
        priority = 100;
      }
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.gemini/settings.json
    assertPathNotExists home-files/.gemini/antigravity-cli/settings.json
    assertFileExists home-files/.gemini/commands/review.toml
    assertFileExists home-files/.gemini/skills/audit/SKILL.md
    assertFileExists home-files/.gemini/policies/commands.toml
    assertPathNotExists home-files/.gemini/antigravity-cli/skills/review/SKILL.md
    assertPathNotExists home-files/.gemini/config/mcp_config.json
  '';
}
