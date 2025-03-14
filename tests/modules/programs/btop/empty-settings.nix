{
  programs.btop.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/btop
  '';
}
