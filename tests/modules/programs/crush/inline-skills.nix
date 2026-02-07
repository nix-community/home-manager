{
  programs.crush = {
    enable = true;

    settings = {
      options = {
        skills_paths = [ "~/.config/crush/skills" ];
      };
    };

    skills = {
      # Inline string skill
      pdf-processing = ''
        ---
        name: pdf-processing
        description: Extract text and tables from PDF files
        ---

        # PDF Processing

        Use pdfplumber to extract text from PDFs.
      '';

      # Skills from file paths
      test-skill = ./skills/test-skill.md;
      standalone-skill = ./skills/standalone-skill.md;

      # Directory-based skill
      directory-skill = ./skills/directory-skill;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/crush/crush.json

    # Verify inline string skill
    assertFileExists home-files/.config/crush/skills/pdf-processing.md
    assertFileRegex home-files/.config/crush/skills/pdf-processing.md "PDF Processing"
    assertFileRegex home-files/.config/crush/skills/pdf-processing.md "pdfplumber"

    # Verify file-based skills
    assertFileExists home-files/.config/crush/skills/test-skill.md
    assertFileRegex home-files/.config/crush/skills/test-skill.md "Test Skill"

    assertFileExists home-files/.config/crush/skills/standalone-skill.md
    assertFileRegex home-files/.config/crush/skills/standalone-skill.md "Standalone Skill"

    # Verify directory-based skill
    assertDirectoryExists home-files/.config/crush/skills/directory-skill
    assertFileExists home-files/.config/crush/skills/directory-skill/SKILL.md
    assertFileRegex home-files/.config/crush/skills/directory-skill/SKILL.md "Directory Skill"
    assertFileExists home-files/.config/crush/skills/directory-skill/README.md
  '';
}
