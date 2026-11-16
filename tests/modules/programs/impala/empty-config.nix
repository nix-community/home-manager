{
  programs.impala.enable = true;

  nmt.script = ''
    assertPathNotExists "home-files/.config/impala"
  '';
}
