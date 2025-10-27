{ config, lib, ... }:
{
  programs.delta = {
    enable = true;
    enableJujutsuIntegration = true;
  };

  programs.jujutsu.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/jj/config.toml
    assertFileContent home-files/.config/jj/config.toml ${builtins.toFile "expected" ''
      [merge-tools.delta]
      diff-expected-exit-codes = [0, 1]

      [ui]
      diff-formatter = ":git"
      pager = "${lib.getExe config.programs.delta.package}"
    ''}
  '';
}
