{
  programs.worktrunk.enable = true;
  nmt.script = ''
    assertPathNotExists home-files/.config/worktrunk/config.toml
  '';
}
