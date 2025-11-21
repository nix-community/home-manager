{
  programs.opencode = {
    enable = true;
    rules = "";
  };
  nmt.script = ''
    assertPathNotExists home-files/.config/opencode/AGENTS.md
  '';
}
