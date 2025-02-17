{
  programs.alacritty.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/alacritty
  '';
}
