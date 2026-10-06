{
  programs.pi-coding-agent = {
    enable = true;
    appendSystem = ''
      # Additional System Instructions

      Prefer concise answers.
      Always explain destructive commands before running them.
    '';
  };
  nmt.script = ''
    assertFileExists home-files/.pi/agent/APPEND_SYSTEM.md
    assertFileContent home-files/.pi/agent/APPEND_SYSTEM.md \
      ${./append-system.md}
  '';
}
