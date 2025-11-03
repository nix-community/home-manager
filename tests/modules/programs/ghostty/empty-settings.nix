{ config, ... }:
{
  programs.ghostty = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = null; };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/ghostty/config
  '';
}
