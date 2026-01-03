{
  programs.opencode = {
    enable = true;
    skills = {
      pdf-processing = ./pdf-processing-SKILL.md;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/skill/pdf-processing/SKILL.md
    assertFileContent home-files/.config/opencode/skill/pdf-processing/SKILL.md \
      ${./pdf-processing-SKILL.md}
  '';
}
