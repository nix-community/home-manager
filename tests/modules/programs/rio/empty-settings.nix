{ config, ... }:
{
  programs.rio.enable = true;
  programs.rio.package = config.lib.test.mkStubPackage { };

  nmt.script = ''
    assertPathNotExists home-files/.config/rio
  '';
}
