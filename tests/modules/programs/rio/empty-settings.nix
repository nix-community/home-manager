_:

{
  programs.rio.enable = true;

  test.stubs.rio = { };

  nmt.script = ''
    assertPathNotExists home-files/.config/rio
  '';
}
