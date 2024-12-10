{
  programs.jrnl.enable = true;

  test.stubs.jrnl = { };

  nmt.script = ''
    assertPathNotExists home-files/.config/jrnl
  '';
}
