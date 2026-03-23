{
  programs.w3m.enable = false;

  nmt.script = ''
    assertPathNotExists "home-files/.w3m"
    assertPathNotExists "home-files/.config/w3m"
  '';
}
