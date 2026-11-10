{ config, ... }:
{
  programs.claude-code = {
    enable = true;
    package = null;
    accounts.work.home = ".claude-work";
    settings.theme = "dark";
    context = "Shared account instructions";
    skills.review = "Review carefully";
    commands.review = "Review changes";
    hooks.check = "echo checked";
    plugins.work = ./test-plugin;
  };
  assertions = [
    {
      assertion = !(config.home.sessionVariables ? CLAUDE_CONFIG_DIR);
      message = "An additional account must not change the global Claude home.";
    }
  ];
  nmt.script = ''
    for account in .claude .claude-work; do
      assertFileContent "home-files/$account/settings.json" ${./accounts-settings.json}
      assertFileRegex "home-files/$account/CLAUDE.md" "Shared account instructions"
      assertFileRegex "home-files/$account/skills/review/SKILL.md" "Review carefully"
      assertFileRegex "home-files/$account/commands/review.md" "Review changes"
      assertFileIsExecutable "home-files/$account/hooks/check"
      assertLinkExists "home-files/$account/skills/work"
      assertFileContent "home-files/$account/skills/work/.claude-plugin/plugin.json" ${./test-plugin/.claude-plugin/plugin.json}
      assertPathNotExists "home-files/$account/.credentials.json"
      assertPathNotExists "home-files/$account/projects"
    done
  '';
}
