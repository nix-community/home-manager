{
  programs.sqlite.enable = false;

  nmt.script = ''
    assertPathNotExists home-files/.config/sqlite
  '';
}
