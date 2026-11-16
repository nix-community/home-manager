{
  programs.gtt = {
    enable = true;
  };

  test.stubs.gtt.name = "gtt";

  nmt.script = ''
    assertPathNotExists home-files/.config/gtt
  '';
}
