{
  programs.starship.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/starship.toml
  '';
}
