{
  programs.silicon.enable = true;

  test.stubs.silicon = { };

  nmt.script = ''
    assertPathNotExists "home-files/.config/silicon/config"
  '';
}
