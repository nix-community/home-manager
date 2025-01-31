{
  programs.foot.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/foot
  '';
}
