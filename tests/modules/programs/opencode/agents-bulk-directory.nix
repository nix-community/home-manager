{
  programs.opencode = {
    enable = true;
    agents = ./agents-bulk;
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/agent/code-reviewer.md
    assertFileExists home-files/.config/opencode/agent/documentation.md
    assertFileContent home-files/.config/opencode/agent/code-reviewer.md \
      ${./agents-bulk/code-reviewer.md}
    assertFileContent home-files/.config/opencode/agent/documentation.md \
      ${./agents-bulk/documentation.md}
  '';
}
