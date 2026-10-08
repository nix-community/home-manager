{
  programs.dprint.enable = true;
  nmt.script = ''
    assertPathNotExists home-files/.config/dprint
  '';
}
