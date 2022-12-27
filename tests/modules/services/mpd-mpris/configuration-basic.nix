{ ... }:

{
  services.mpd-mpris = { enable = true; };

  test.stubs.mpd-mpris = { };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/mpd-mpris.service
    assertFileContent "$serviceFile" ${./configuration-basic.service}
  '';
}
