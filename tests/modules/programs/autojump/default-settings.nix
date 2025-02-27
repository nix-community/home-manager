{
  programs.autojump.enable = true;

  test.stubs.autojump = {
    buildScript = "mkdir -p $out/bin; touch $out/bin/autojump";
    outPath = null;
  };

  nmt.script = ''
    assertFileExists home-path/bin/autojump
  '';
}
