{ config, ... }:
{
  programs.rift-wm = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "rift-wm"; };
  };

  nmt.script = ''
    assertPathNotExists "home-files/.config/rift"
  '';
}
