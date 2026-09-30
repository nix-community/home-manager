{
  programs.pi-coding-agent = {
    enable = true;
    appendSystem = ./append-system.md;
  };
  nmt.script = ''
    assertFileExists home-files/.pi/agent/APPEND_SYSTEM.md
    assertFileContent home-files/.pi/agent/APPEND_SYSTEM.md \
      ${./append-system.md}
  '';
}
