{
  programs.claude-code = {
    enable = true;
    skills = {
      test-skill = ./test-skill.md;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.claude/skills/test-skill/SKILL.md
    assertFileContent home-files/.claude/skills/test-skill/SKILL.md \
      ${./test-skill.md}
  '';
}
