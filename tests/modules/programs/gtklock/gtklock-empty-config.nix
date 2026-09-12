_: {
  programs.gtklock.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/gtklock/config.ini
  '';
}
