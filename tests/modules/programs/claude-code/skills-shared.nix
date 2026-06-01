{
  programs = {
    agent-skills = {
      enable = true;
      bundles = [
        ../agent-skills/shared-bundle
        ../agent-skills/override-bundle
      ];
      skills = {
        single-skill = ../agent-skills/single-skill;
        standalone = ../agent-skills/standalone/SKILL.md;
        inline-shared = ''
          ---
          name: inline-shared
          description: Inline skill defined via shared agent-skills.
          ---
        '';
      };
    };
    claude-code = {
      enable = true;
      enableSkillsIntegration = true;
      skills = {
        claude-only = ''
          ---
          name: claude-only
          description: Skill defined only for Claude Code.
          ---
        '';
        shared-overridden = ''
          ---
          name: shared-overridden
          description: Per-agent override.
          ---
        '';
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.claude/skills/shared-only/SKILL.md
    assertFileExists home-files/.claude/skills/single-skill/SKILL.md
    assertFileExists home-files/.claude/skills/standalone/SKILL.md
    assertFileExists home-files/.claude/skills/inline-shared/SKILL.md
    assertFileExists home-files/.claude/skills/claude-only/SKILL.md
    assertFileExists home-files/.claude/skills/shared-overridden/SKILL.md
    assertFileRegex home-files/.claude/skills/shared-only/SKILL.md \
      'Shared skill exposed to every agent.'
    assertFileRegex home-files/.claude/skills/single-skill/SKILL.md \
      'Skill exposed via a single-skill directory.'
    assertFileRegex home-files/.claude/skills/standalone/SKILL.md \
      'Skill exposed via a direct SKILL.md file path.'
    assertFileRegex home-files/.claude/skills/inline-shared/SKILL.md \
      'Inline skill defined via shared agent-skills.'
    assertFileRegex home-files/.claude/skills/claude-only/SKILL.md \
      'Skill defined only for Claude Code.'
    assertFileRegex home-files/.claude/skills/shared-overridden/SKILL.md \
      'Per-agent override.'
  '';
}
