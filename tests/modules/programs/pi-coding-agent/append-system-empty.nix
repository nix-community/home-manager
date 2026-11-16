{
  programs.pi-coding-agent = {
    enable = true;
    appendSystem = "";
  };
  nmt.script = ''
    assertPathNotExists home-files/.pi/agent/APPEND_SYSTEM.md
  '';
}
