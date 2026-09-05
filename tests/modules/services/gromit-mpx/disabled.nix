{
  services.gromit-mpx.enable = false;

  nmt.script = ''
    assertPathNotExists home-files/.config/gromit-mpx.ini
    assertPathNotExists home-files/.config/gromit-mpx.cfg
    assertPathNotExists home-files/.config/systemd/user/gromit-mpx.service
  '';
}
