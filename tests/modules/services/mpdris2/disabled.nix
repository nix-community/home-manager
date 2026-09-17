{
  services.mpdris2.settings.Library.music_dir = "/music";

  nmt.script = ''
    assertPathNotExists home-files/.config/mpDris2/mpDris2.conf
    assertPathNotExists home-files/.config/systemd/user/mpdris2.service
  '';
}
