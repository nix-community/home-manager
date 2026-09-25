{
  programs.cursor-agent = {
    enable = true;
    package = null;

    skills = {
      pdf-processing = ''
        ---
        name: pdf-processing
        description: Extract text and tables from PDF files
        ---

        # PDF Processing

        Use pdfplumber to extract text from PDFs.
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.cursor/skills/pdf-processing/SKILL.md
    assertFileContent home-files/.cursor/skills/pdf-processing/SKILL.md \
      ${./expected-pdf-processing-skill.md}
  '';
}
