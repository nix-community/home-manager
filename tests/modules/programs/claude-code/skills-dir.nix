{
  programs.claude-code = {
    enable = true;
    skillsDir = ./skills;
  };

  nmt.script = ''
    assertFileExists home-files/.claude/skills/test-skill.md
    assertLinkExists home-files/.claude/skills/test-skill.md
    assertFileContent \
      home-files/.claude/skills/test-skill.md \
      ${./skills/test-skill.md}
  '';
}
