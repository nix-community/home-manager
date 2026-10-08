{
  programs.stylua.enable = true;
  nmt.script = ''
    assertPathNotExists "home-files/.config/stylua"
  '';
}
