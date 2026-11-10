{ config, ... }:
{
  programs.codex = {
    enable = true;
    package = null;
    accounts.work.home = ".codex-work";
    settings.model = "shared";
    context = "Shared account instructions";
    skills.review = "Review carefully";
    rules.safety = "allow()";
    profiles.review.model = "review-model";
    hooks.PreToolUse = [
      {
        matcher = "Bash";
        hooks = [
          {
            type = "command";
            command = "rtk hook codex";
          }
        ];
      }
    ];
  };
  assertions = [
    {
      assertion = !(config.home.sessionVariables ? CODEX_HOME);
      message = "An additional account must not change the global Codex home.";
    }
  ];
  nmt.script = ''
    for account in .codex .codex-work; do
      assertFileContent "home-files/$account/config.toml" ${./accounts-config.toml}
      assertFileRegex "home-files/$account/AGENTS.md" "Shared account instructions"
      assertFileRegex "home-files/$account/skills/review/SKILL.md" "Review carefully"
      assertFileRegex "home-files/$account/rules/safety.rules" "allow"
      assertFileRegex "home-files/$account/review.config.toml" "review-model"
      assertFileRegex "home-files/$account/hooks.json" "rtk hook codex"
      assertPathNotExists "home-files/$account/auth.json"
      assertPathNotExists "home-files/$account/sessions"
    done
  '';
}
