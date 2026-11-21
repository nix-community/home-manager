{
  agents.skills.skills = {
    shared.text = ''
      ---
      name: shared
      description: Shared skill.
      ---
    '';
    overridden.text = ''
      ---
      name: overridden
      description: Shared skill overridden by Claude Code.
      ---
    '';
    test-plugin.text = ''
      ---
      name: test-plugin
      description: Shared skill overridden by a Claude Code plugin.
      ---
    '';
  };

  programs.claude-code = {
    enable = true;
    enableSkillsIntegration = true;
    skills = {
      test-skill = ./test-skill.md;
      overridden = ''
        ---
        name: overridden
        description: Claude Code skill.
        ---
      '';
    };
    plugins.test-plugin = ./test-plugin;
  };

  nmt.script = ''
    skills=home-files/.claude/skills

    assertFileRegex $skills/shared/SKILL.md '^description: Shared skill\.$'
    assertFileContent $skills/test-skill/SKILL.md ${./test-skill.md}
    assertFileRegex $skills/overridden/SKILL.md '^description: Claude Code skill\.$'
    assertFileContent $skills/test-plugin/.claude-plugin/plugin.json \
      ${./test-plugin/.claude-plugin/plugin.json}
    assertPathNotExists $skills/test-plugin/SKILL.md
  '';
}
