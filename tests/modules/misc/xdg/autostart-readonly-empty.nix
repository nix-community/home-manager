{
  xdg.autostart = {
    enable = true;
    readOnly = true;
  };

  nmt.script = ''
    assertLinkExists home-files/.config/autostart
  '';
}
