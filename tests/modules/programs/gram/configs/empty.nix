{
  programs.gram.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/gram
  '';
}
