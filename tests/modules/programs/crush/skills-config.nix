{
  programs.crush = {
    enable = true;

    skills = {
      pdf-processing = ''
        ---
        name: pdf-processing
        description: Extract text and tables from PDF files
        ---

        # PDF Processing

        Use pdfplumber to extract text from PDFs.
      '';
      xlsx = ''
        ---
        name: xlsx
        description: Work with Excel files
        ---

        # XLSX Processing

        Use openpyxl for Excel file operations.
      '';
    };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/crush/crush.json

    assertFileExists home-files/.config/crush/skills/pdf-processing.md
    assertFileRegex home-files/.config/crush/skills/pdf-processing.md "PDF Processing"
    assertFileRegex home-files/.config/crush/skills/pdf-processing.md "pdfplumber"

    assertFileExists home-files/.config/crush/skills/xlsx.md
    assertFileRegex home-files/.config/crush/skills/xlsx.md "XLSX Processing"
    assertFileRegex home-files/.config/crush/skills/xlsx.md "openpyxl"
  '';
}
