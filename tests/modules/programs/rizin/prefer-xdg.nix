{
  xdg.enable = true;

  home.preferXdgDirectories = true;

  programs.rizin = {
    enable = true;
    extraConfig = ''
      e asm.bytes=true
      e asm.bytes.space=true
    '';
  };

  nmt.script = ''
    assertFileExists "home-files/.config/rizin/rizinrc"
  '';
}
