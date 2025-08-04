{
  fonts.fontconfig.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/fontconfig/conf.d/10-hm-rendering.conf
  '';
}
