{
  programs.ncmpcpp.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/ncmpcpp/config

    assertPathNotExists home-files/.config/ncmpcpp/bindings
  '';
}
