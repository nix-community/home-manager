{
  programs.notmuch.enable = false;

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertPathNotExists home-files/.config/notmuch/default/config
  '';
}
