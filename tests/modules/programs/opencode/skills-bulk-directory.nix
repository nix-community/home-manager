{
  programs.opencode = {
    enable = true;
    skills = ./skills-bulk;
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/skill/git-release/SKILL.md
    assertFileExists home-files/.config/opencode/skill/pdf-processing/SKILL.md
    assertFileContent home-files/.config/opencode/skill/git-release/SKILL.md \
      ${./skills-bulk/git-release/SKILL.md}
    assertFileContent home-files/.config/opencode/skill/pdf-processing/SKILL.md \
      ${./skills-bulk/pdf-processing/SKILL.md}
  '';
}
