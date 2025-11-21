{
  programs.codex = {
    enable = true;
    custom-instructions = "";
  };
  nmt.script = ''
    assertPathNotExists home-files/.codex/AGENTS.md
  '';
}
