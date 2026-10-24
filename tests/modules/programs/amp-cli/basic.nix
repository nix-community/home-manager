{
  programs.amp-cli.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/amp
  '';
}
