{
  programs.less.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/lesskey
  '';
}
