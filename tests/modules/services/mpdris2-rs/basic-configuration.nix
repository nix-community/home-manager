{
  services.mpdris2-rs = {
    enable = true;
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/mpdris2-rs.service
    assertFileContent "$serviceFile" ${./basic-configuration.service}
  '';
}
