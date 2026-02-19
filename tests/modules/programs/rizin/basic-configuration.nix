{
  programs.rizin = {
    enable = true;
    extraConfig = ''
      e asm.bytes=true
      e asm.bytes.space=true
    '';
  };

  nmt.script = ''
    assertFileExists "home-files/.rizinrc"
  '';
}
