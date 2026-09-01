{
  programs.mpv = {
    enable = true;
    settings.title = "line\nvalue";
    profiles.multiline.profile-desc = "profile\nvalue";
  };

  nmt.script = ''
    assertFileContains home-files/.config/mpv/mpv.conf 'title=%10%line'
    assertFileContains home-files/.config/mpv/mpv.conf 'profile-desc=%13%profile'
    assertFileContains home-files/.config/mpv/mpv.conf 'value'
  '';
}
