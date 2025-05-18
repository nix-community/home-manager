{
  programs.wayprompt.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/wayprompt
  '';
}
