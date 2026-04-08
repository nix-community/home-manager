{
  programs.gemini-cli = {
    enable = true;
    skills = {
      xlsx = ./skills/xlsx/SKILL.md;
      data-analysis = ./skills/data-analysis;
      pdf-processing = ''
        ---
        name: pdf-processing
        description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
        ---

        # PDF Processing

        ## Quick start

        Use pdfplumber to extract text from PDFs:

        ```python
        import pdfplumber

        with pdfplumber.open("document.pdf") as pdf:
            text = pdf.pages[0].extract_text()
        ```
      '';
    };
  };
  nmt.script = ''
    assertFileExists home-files/.gemini/skills/xlsx/SKILL.md
    assertFileContent home-files/.gemini/skills/xlsx/SKILL.md \
      ${./skills/xlsx/SKILL.md}

    assertFileExists home-files/.gemini/skills/data-analysis/SKILL.md
    assertFileContent home-files/.gemini/skills/data-analysis/SKILL.md \
      ${./skills/data-analysis/SKILL.md}

    assertFileExists home-files/.gemini/skills/pdf-processing/SKILL.md
    assertFileContent home-files/.gemini/skills/pdf-processing/SKILL.md \
      ${./skills/pdf-processing/SKILL.md}
  '';
}
