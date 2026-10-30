{
  programs.tuicr = {
    enable = true;
    settings = { };
  };

  test.stubs.tuicr = {
    name = "tuicr";
    outPath = null;
    buildScript = ''
      mkdir -p $out/bin
      touch $out/bin/tuicr
    '';
  };

  nmt.script = ''
    assertPathNotExists "home-files/.config/tuicr/config.toml"
    assertPathNotExists "home-files/.config/tuicr/themes"
    assertFileExists "home-path/bin/tuicr"
  '';
}
