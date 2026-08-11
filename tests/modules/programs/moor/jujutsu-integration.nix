{ config, ... }:
{
  programs.moor = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "moor";
      outPath = "@moor@";
    };
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
