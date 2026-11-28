{ config, ... }:

{
  programs.warp-terminal = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/warp-terminal
    assertPathNotExists home-files/.local/share/warp-terminal
    assertPathNotExists home-files/.warp
  '';
}
