{
  programs.pi-coding-agent = {
    enable = true;
    context = ./context-inline.md;
  };
  nmt.script = ''
    assertFileExists home-files/.pi/agent/AGENTS.md
    assertFileContent home-files/.pi/agent/AGENTS.md \
      ${./context-inline.md}
  '';
}
