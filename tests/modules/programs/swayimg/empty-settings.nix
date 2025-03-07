{
  programs.swayimg.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/swayimg
  '';
}
