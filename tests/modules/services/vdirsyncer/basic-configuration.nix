{
  services.vdirsyncer.enable = true;

  nmt.script = ''
    assertFileContent home-files/.config/systemd/user/vdirsyncer.service \
                      ${./vdirsyncer-expected.service}
  '';
}
