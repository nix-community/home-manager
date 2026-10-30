{
  agents.skills.skills = {
    shared.text = ''
      ---
      name: shared
      description: Shared skill.
      ---
    '';
    test-skill.text = ''
      ---
      name: test-skill
      description: Shared skill overridden by Claude Code.
      ---
    '';
  };

  programs.claude-code = {
    enable = true;
    enableSkillsIntegration = true;
    skills = ./skills;
  };

  nmt.script = ''
    skills=home-files/.claude/skills

    assertFileRegex $skills/shared/SKILL.md '^description: Shared skill\.$'
    assertFileContent $skills/test-skill/SKILL.md ${./skills/test-skill/SKILL.md}
  '';
}
