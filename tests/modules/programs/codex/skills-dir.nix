{
  programs.codex = {
    enable = true;
    skillsDir = ./skills-dir;
  };

  nmt.script = ''
    assertFileExists home-files/.codex/skills/skill-one/SKILL.md
    assertFileRegex home-files/.codex/skills/skill-one/SKILL.md "Skill One"
  '';
}
