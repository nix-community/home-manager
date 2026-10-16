{
  programs.radare2 = {
    enable = true;
    settings = {
      "scr.color" = 2;
      "scr.utf8" = true;
      "asm.describe" = false;
    };
    extraConfig = ''
      eco bobcrawl
    '';
  };

  nmt.script = ''
    assertFileContent "home-files/.config/radare2/rc" ${./expected-rc}
    assertPathNotExists "home-files/.config/radare2/radare2rc"
  '';
}
