{
  aria2.enable = false;

  nmt.script = ''
    assertPathNotExists "home-files/.config/aria2"
  '';
}
