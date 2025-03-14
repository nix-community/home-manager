{
  services.mpd-mpris = { enable = true; };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/mpd-mpris.service
    assertFileContent "$serviceFile" ${./configuration-basic.service}
  '';
}
