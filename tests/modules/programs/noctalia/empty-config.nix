{
  programs.noctalia.enable = true;

  nmt.script = ''
    assertPathNotExists "home-files/.config/noctalia";
  '';
}
