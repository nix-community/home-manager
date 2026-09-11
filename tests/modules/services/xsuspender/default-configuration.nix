{
  services.xsuspender.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/xsuspender.conf
    assertFileExists home-files/.config/systemd/user/xsuspender.service
  '';
}
