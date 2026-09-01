{
  xdg.enable = true;

  programs.herdr.enable = true;

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertPathNotExists "home-files/.config/herdr/config.toml"
  '';
}
