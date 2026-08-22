{
  programs.pi-coding-agent = {
    enable = true;
    skills = ./skills;
  };

  nmt.script = ''
    assertFileExists home-files/.pi/agent/skills/my-skill/SKILL.md
    assertFileContent home-files/.pi/agent/skills/my-skill/SKILL.md \
      ${./skills/my-skill/SKILL.md}
  '';
}
