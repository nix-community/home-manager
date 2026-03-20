{
  programs.claude-code = {
    enable = true;
    memory = {
      source = ./expected-memory.md;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.claude/CLAUDE.md
    assertFileContent home-files/.claude/CLAUDE.md ${./expected-memory.md}
  '';
}
