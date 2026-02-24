{
  programs.rizin = {
    enable = true;
    settings = {
      "asm.bytes" = true;
      "asm.bytes.space" = true;
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.rizinrc"
  '';
}
