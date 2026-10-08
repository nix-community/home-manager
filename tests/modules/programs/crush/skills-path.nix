{
  programs.crush = {
    enable = true;
    package = null;

    skills = ./skills-bulk;
  };

  nmt.script = ''
    assertFileContent home-files/.config/crush/skills/code-review/SKILL.md \
      ${./skills-bulk/code-review/SKILL.md}
  '';
}
