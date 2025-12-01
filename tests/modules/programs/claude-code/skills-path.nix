{
  programs.claude-code = {
    enable = true;
    skills = {
      test-skill = ./test-skill.md;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.claude/skills/test-skill.md
    assertFileContent home-files/.claude/skills/test-skill.md \
      ${./test-skill.md}
  '';
}
