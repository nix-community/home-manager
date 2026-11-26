{
  services.shpool.enable = true;
  test.stubs.shpool = { };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/shpool.service
    assertFileExists home-files/.config/systemd/user/shpool.socket
  '';
}
