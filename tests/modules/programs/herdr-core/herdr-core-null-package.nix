_: {
  xdg.enable = true;

  programs.herdr.core = {
    enable = true;
    package = null;
    settings.shell = [ "nu" ];
  };

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertFileExists "home-files/.config/herdr-core/config.toml"
  '';
}
