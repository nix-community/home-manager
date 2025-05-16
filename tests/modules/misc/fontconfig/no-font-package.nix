{
  home.packages = [
    # Look, no font!
  ];

  fonts.fontconfig.enable = true;

  nmt.script = ''
    assertPathNotExists home-path/lib/fontconfig/cache
    assertLinkExists home-path/etc/fonts/fonts.conf
    assertDirectoryExists home-path/etc/fonts/conf.d
  '';
}
