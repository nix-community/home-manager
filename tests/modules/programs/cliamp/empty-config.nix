{
  programs.cliamp.enable = true;

  nmt.script = ''
    assertPathNotExists "home-files/.config/cliamp"
  '';
}
