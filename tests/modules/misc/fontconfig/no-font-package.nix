{
  home.packages = [
    # Look, no font!
  ];

  fonts.fontconfig.enable = true;

  nmt.script = ''
    assertPathNotExists home-path/lib/fontconfig/cache
  '';
}
