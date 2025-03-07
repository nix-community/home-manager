{
  programs.rio.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/rio
  '';
}
