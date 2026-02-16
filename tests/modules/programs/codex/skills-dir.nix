{
  programs.codex = {
    enable = true;
    skills = ./skills-dir;
  };

  nmt.script = ''
    assertFileExists home-files/.codex/skills/skill-one/SKILL.md
    assertFileContent home-files/.codex/skills/skill-one/SKILL.md \
      ${./skills-dir/skill-one/SKILL.md}
  '';
}
