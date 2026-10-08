{
  programs.pi-coding-agent = {
    enable = true;
    context = "";
  };
  nmt.script = ''
    assertPathNotExists home-files/.pi/agent/AGENTS.md
  '';
}
