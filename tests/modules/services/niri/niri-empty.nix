{ config, ... }:

{
  wayland.windowManager.niri = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@niri@"; };
  };

  nmt.script = ''
    assertFileExists home-files/.config/niri/config.kdl
    assertFileContent $(normalizeStorePaths home-files/.config/niri/config.kdl) \
      ${./niri-empty.kdl}
  '';
}
