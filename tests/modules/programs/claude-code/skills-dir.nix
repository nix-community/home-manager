{
  programs.claude-code = {
    enable = true;
    skillsDir = ./skills;
  };

  nmt.script = ''
    assertFileExists home-files/.claude/skills/test-skill/SKILL.md
    assertLinkExists home-files/.claude/skills/test-skill/SKILL.md
    assertFileContent \
      home-files/.claude/skills/test-skill/SKILL.md \
      ${./skills/test-skill/SKILL.md}
  '';
}
