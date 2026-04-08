{
  programs.opencode = {
    enable = true;
    context = "";
  };
  nmt.script = ''
    assertPathNotExists home-files/.config/opencode/AGENTS.md
  '';
}
