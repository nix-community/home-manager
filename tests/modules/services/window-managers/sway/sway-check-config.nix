{ config, lib, ... }:

lib.mkIf config.test.enableBig {
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
  '';
}
