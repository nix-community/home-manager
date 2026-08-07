{
  programs.concord = {
    enable = true;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/concord/config.toml
    assertPathNotExists home-files/.config/concord/keymap.toml
    assertPathNotExists home-files/.config/concord/theme.toml
  '';
}
