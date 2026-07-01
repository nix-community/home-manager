{
  programs.wiremix.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/wiremix
  '';
}
