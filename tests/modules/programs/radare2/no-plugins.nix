{
  programs.radare2.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.local/share/radare2
    assertPathNotExists home-files/.config/radare2
  '';
}
