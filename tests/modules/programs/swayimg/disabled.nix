{ ... }: {

  nmt.script = ''
    assertPathNotExists home-files/.config/swayimg/config
  '';
}
