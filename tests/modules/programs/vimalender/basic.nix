{
  programs.vimalender.enable = true;

  test.stubs.vimalender = {
    name = "vimalender";
    outPath = null;
    buildScript = ''
      mkdir -p $out/bin
      touch $out/bin/vimalender
      chmod +x $out/bin/vimalender
    '';
  };

  nmt.script = ''
    assertFileExists home-path/bin/vimalender
  '';
}
