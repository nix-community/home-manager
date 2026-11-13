{
  programs.moor = {
    enable = true;
    enableJujutsuIntegration = true;
  };

  programs.jujutsu.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/jj/config.toml
    assertFileContent home-files/.config/jj/config.toml ${builtins.toFile "expected" ''
      [ui]
      pager = "@moor@/bin/moor"
    ''}
  '';
}
