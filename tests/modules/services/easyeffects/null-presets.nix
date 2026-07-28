{
  services.easyeffects = {
    enable = true;
    extraPresets = null;
  };

  test.stubs.easyeffects = { };

  nmt.script = ''
    assertPathNotExists home-files/.local/share/easyeffects/input
    assertPathNotExists home-files/.local/share/easyeffects/output
  '';
}
