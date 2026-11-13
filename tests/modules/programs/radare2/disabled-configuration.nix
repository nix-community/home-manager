{
  programs.radare2 = {
    enable = false;
    settings."scr.utf8" = true;
  };

  nmt.script = ''
    assertPathNotExists "home-files/.radare2rc"
    assertPathNotExists "home-files/.config/radare2"
  '';
}
