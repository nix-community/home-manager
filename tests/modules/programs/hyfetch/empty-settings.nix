{
  programs.hyfetch.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/hyfetch.json
  '';
}
