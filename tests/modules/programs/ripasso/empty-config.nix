{
  programs.ripasso.enable = true;

  nmt.script = ''
    assertPathNotExists "home-files/.config/ripasso"
  '';
}
