{
  programs.yambar.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/yambar
  '';
}
