{
  programs.lnav.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/lnav/config.json
    assertPathNotExists home-files/.config/lnav/formats/installed
  '';
}
