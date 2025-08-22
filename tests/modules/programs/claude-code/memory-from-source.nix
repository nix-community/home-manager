{
  programs.claude-code = {
    enable = true;
    memory = {
      source = ./expected-memory.md;
    };
  };

  nmt.script = ''
    assertFileExists home-files/CLAUDE.md
    assertFileContent home-files/CLAUDE.md ${./expected-memory.md}
  '';
}
