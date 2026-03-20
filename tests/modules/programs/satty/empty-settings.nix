{
  programs.satty.enable = false;

  nmt.script = ''
    assertPathNotExists "home-files/.config/satty"
  '';
}
