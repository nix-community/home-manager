{
  xsession.numlock.enable = true;

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/numlockx.service
    assertFileExists $serviceFile
  '';
}
