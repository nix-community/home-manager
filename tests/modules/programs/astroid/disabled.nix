{
  programs.astroid.enable = false;

  nmt.script = ''
    assertPathNotExists home-files/.config/astroid
  '';
}
