{
  programs.opencode.enable = true;
  nmt.script = ''
    assertPathNotExists home-files/.config/opencode/tui.json
  '';
}
