{
  programs.gemini-cli = {
    enable = true;
    context = ./context.md;
  };
  nmt.script = ''
    assertFileExists home-files/.gemini/GEMINI.md
    assertFileContent home-files/.gemini/GEMINI.md \
      ${./context.md}
  '';
}
