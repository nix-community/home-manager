{
  programs.radare2 = {
    enable = true;
    package = null;
    settings."scr.utf8" = true;
  };

  nmt.script = ''
    assertFileExists "home-files/.config/radare2/rc"
    assertPathNotExists "home-path/bin/radare2"
  '';
}
