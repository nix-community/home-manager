{ ... }: {
  programs.swaylock.settings = { };

  nmt.script = ''
    assertPathNotExists home-files/.config/swaylock/config
  '';
}
