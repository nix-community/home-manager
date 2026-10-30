{
  programs.tuicr = {
    enable = false;
    settings = {
      theme = "catppuccin-mocha";
      diff_view = "unified";
      scroll_offset = 5;
      leader = ";";
      comment_vim = false;
    };
    themes.my-theme = ./my-theme.toml;
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
    assertPathNotExists "home-path/bin/tuicr"
    assertPathNotExists "home-files/.config/tuicr/themes"
    assertPathNotExists "home-files/.config/tuicr/config.toml"
  '';
}
