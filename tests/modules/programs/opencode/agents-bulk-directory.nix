{
  programs.opencode = {
    enable = true;
    agents = ./agents-bulk;
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/agents/code-reviewer.md
    assertFileExists home-files/.config/opencode/agents/documentation.md
    assertFileContent home-files/.config/opencode/agents/code-reviewer.md \
      ${./agents-bulk/code-reviewer.md}
    assertFileContent home-files/.config/opencode/agents/documentation.md \
      ${./agents-bulk/documentation.md}
  '';
}
