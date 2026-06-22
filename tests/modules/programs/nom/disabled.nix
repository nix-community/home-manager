{
  programs.nom.enable = false;

  nmt.script = ''
    assertPathNotExists "home-files/.config/nom"
  '';
}
