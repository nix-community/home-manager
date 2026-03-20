{
  services.mpd-mpris = {
    enable = true;
    mpd.useLocal = true;
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/mpd-mpris.service
    assertFileContent "$serviceFile" ${./configuration-with-local-mpd.service}
  '';
}
