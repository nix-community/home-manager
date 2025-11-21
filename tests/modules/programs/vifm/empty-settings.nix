{
  programs.vifm.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/vifm
  '';
}
