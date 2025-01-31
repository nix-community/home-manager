{
  services.syncthing.tray.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/syncthingtray.service
  '';
}
