{
  programs.eilmeldung.enable = true;

  nmt.script = ''
    assertPathNotExists "home-files/.config/eilmeldung"
  '';
}
