{
  programs.vinegar.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/vinegar/config.toml
  '';
}
