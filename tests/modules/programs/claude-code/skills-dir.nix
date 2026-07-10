{
  programs.claude-code = {
    enable = true;
    skills = ./skills;
    plugins = [ ./test-plugin ];
  };

  nmt.script = ''
    assertFileExists home-files/.claude/skills/test-skill/SKILL.md
    assertLinkExists home-files/.claude/skills/test-skill/SKILL.md
    assertFileContent \
      home-files/.claude/skills/test-skill/SKILL.md \
      ${./skills/test-skill/SKILL.md}
    assertFileContent \
      home-files/.claude/skills/${baseNameOf (toString ./test-plugin)}/.claude-plugin/plugin.json \
      ${./test-plugin/.claude-plugin/plugin.json}
  '';
}
