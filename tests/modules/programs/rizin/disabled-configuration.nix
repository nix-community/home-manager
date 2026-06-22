{
  programs.rizin = {
    enable = false;
    extraConfig = ''
      e asm.bytes=true
      e asm.bytes.space=true
    '';
  };

  nmt.script = ''
    assertPathNotExists "home-files/.rizinrc"
    assertPathNotExists "home-files/.config/rizin/rizinrc"
  '';
}
