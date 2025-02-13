{
  services.copyq = {
    enable = true;
    systemdTarget = "sway-session.target";
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/copyq.service
    assertFileContent $serviceFile ${./basic-expected.service}
  '';
}
