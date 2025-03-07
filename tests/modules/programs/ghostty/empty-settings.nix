{
  programs.ghostty.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/ghostty/config
  '';
}
