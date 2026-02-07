{
  programs.crush.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/crush
  '';
}
