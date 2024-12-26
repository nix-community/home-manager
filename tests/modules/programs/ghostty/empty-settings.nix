{
  programs.ghostty.enable = true;
  test.stubs.ghostty = { };
  nmt.script = ''
    assertPathNotExists home-files/.config/ghostty/config
  '';
}
