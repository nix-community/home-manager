{
  programs.opencode = {
    enable = true;
    rules = ./AGENTS.md;
  };
  nmt.script = ''
    assertFileExists home-files/.config/opencode/AGENTS.md
    assertFileContent home-files/.config/opencode/AGENTS.md \
      ${./AGENTS.md}
  '';
}
