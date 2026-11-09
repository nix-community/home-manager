{ config, ... }:
{
  programs.mitos = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "mitos"; };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/mitos
  '';
}
