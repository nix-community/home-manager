{
  programs.feh.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/feh/buttons
    assertPathNotExists home-files/.config/feh/keys
    assertPathNotExists home-files/.config/feh/themes
  '';
}
