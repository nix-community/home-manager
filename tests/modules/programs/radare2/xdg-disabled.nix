{
  xdg.enable = false;

  programs.radare2 = {
    enable = true;
    extraConfig = "e scr.utf8=true";
  };

  nmt.script = ''
    assertFileContent "home-files/.radare2rc" ${./xdg-disabled-rc}
    assertPathNotExists "home-files/.config/radare2"
  '';
}
