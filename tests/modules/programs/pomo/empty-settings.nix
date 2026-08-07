{
  programs.pomo.enable = true;
  nmt.script = ''
    assertPathNotExists home-files/.config/pomo
  '';
}
