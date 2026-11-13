{
  programs.tuicr = {
    enable = true;
    themes.my-theme = ./my-theme.toml;
    settings.theme = "my-theme";
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
    assertFileExists "home-files/.config/tuicr/themes/my-theme.toml"
    assertFileContent "home-files/.config/tuicr/themes/my-theme.toml" ${./my-theme.toml}
    assertFileRegex "home-files/.config/tuicr/config.toml" 'theme = "my-theme"'
  '';
}
