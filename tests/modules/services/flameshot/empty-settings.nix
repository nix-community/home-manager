{
  services.flameshot.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/flameshot/flameshot.ini
  '';
}
