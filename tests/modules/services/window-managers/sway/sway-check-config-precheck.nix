{ config, lib, ... }:

lib.mkIf config.test.enableBig {
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = true;
    preCheckConfig = ''
      export HOME=$(mktemp -d)
      touch ~/mybg.png
    '';
    config.output."*".background = "~/mybg.png fill";
  };

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
  '';
}
