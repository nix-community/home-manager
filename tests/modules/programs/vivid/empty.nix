{
  programs.vivid = {
    enable = true;
    theme = "test";
  };
  test.stubs.vivid = { };
  nmt.script = ''
    assertPathNotExists home-files/.config/vivid/filetypes.yaml
    assertPathNotExists home-files/.config/vivid/themes
  '';
}
