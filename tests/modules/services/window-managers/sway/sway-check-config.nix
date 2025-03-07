{ config, lib, realPkgs, ... }:

lib.mkIf config.test.enableBig {
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = true;
  };

  nixpkgs.overlays = [ (self: super: { inherit (realPkgs) xvfb-run; }) ];

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
  '';
}
