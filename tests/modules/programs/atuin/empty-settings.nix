{
  programs.atuin.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/atuin/config.toml
  '';
}
