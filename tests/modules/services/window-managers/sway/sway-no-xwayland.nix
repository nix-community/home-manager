{ config, ... }:

{
  wayland.windowManager.sway = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@sway@"; };
    checkConfig = false;
    config = null;
    systemd.enable = false;
    xwayland = false;
  };

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
    assertFileContent $(normalizeStorePaths home-files/.config/sway/config) \
        ${
          builtins.toFile "expected" ''
            xwayland disable
          ''
        }
  '';
}
