{
  programs.gemini-cli = {
    enable = true;
    skills = ./skills;
  };

  nmt.script = ''
    assertFileExists home-files/.gemini/skills/xlsx/SKILL.md
    assertLinkExists home-files/.gemini/skills/xlsx/SKILL.md
    assertFileContent home-files/.gemini/skills/xlsx/SKILL.md \
      ${./skills/xlsx/SKILL.md}

    assertFileExists home-files/.gemini/skills/data-analysis/SKILL.md
    assertLinkExists home-files/.gemini/skills/data-analysis/SKILL.md
    assertFileContent home-files/.gemini/skills/data-analysis/SKILL.md \
      ${./skills/data-analysis/SKILL.md}

    assertFileExists home-files/.gemini/skills/pdf-processing/SKILL.md
    assertLinkExists home-files/.gemini/skills/pdf-processing/SKILL.md
    assertFileContent home-files/.gemini/skills/pdf-processing/SKILL.md \
      ${./skills/pdf-processing/SKILL.md}
  '';
}
