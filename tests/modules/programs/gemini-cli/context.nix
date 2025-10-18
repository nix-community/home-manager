{
  programs.gemini-cli = {
    enable = true;
    context = {
      # Test inline content
      GEMINI = ''
        # Global Context

        You are a helpful AI assistant for software development.

        ## Coding Standards

        - Follow consistent code style
        - Write clear comments
        - Test your changes
      '';
      # Test file path
      AGENTS = ./context.md;
      # Test another inline content
      CONTEXT = ''
        Additional context for specialized tasks.
      '';
    };
    settings = {
      context.fileName = [
        "AGENTS.md"
        "CONTEXT.md"
        "GEMINI.md"
      ];
    };
  };
  nmt.script = ''
    assertFileExists home-files/.gemini/GEMINI.md
    assertFileContent home-files/.gemini/GEMINI.md \
      ${./context-inline.md}

    assertFileExists home-files/.gemini/AGENTS.md
    assertFileContent home-files/.gemini/AGENTS.md \
      ${./context.md}

    assertFileExists home-files/.gemini/CONTEXT.md
    assertFileContent home-files/.gemini/CONTEXT.md \
      ${./context-additional.md}
  '';
}
