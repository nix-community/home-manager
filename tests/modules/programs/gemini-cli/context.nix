{
  programs.gemini-cli = {
    enable = true;
    context = ''
      # Global Context

      You are a helpful AI assistant for software development.

      ## Coding Standards

      - Follow consistent code style
      - Write clear comments
      - Test your changes
    '';
  };
  nmt.script = ''
    assertFileExists home-files/.gemini/GEMINI.md
    assertFileContent home-files/.gemini/GEMINI.md \
      ${./context.md}
  '';
}
