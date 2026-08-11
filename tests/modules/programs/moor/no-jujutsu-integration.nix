{ config, ... }:
{
  programs.moor = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "moor";
      outPath = "@moor@";
    };
    enableJujutsuIntegration = false;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/jj/config.toml
  '';
}
