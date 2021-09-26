{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ./sway-stubs.nix ];

  wayland.windowManager.sway = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@sway@"; };

    config = {
      focus.followMouse = false;
      menu = "${pkgs.dmenu}/bin/dmenu_run";
      bars = [ ];
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
    assertFileContent home-files/.config/sway/config \
      ${./sway-followmouse-legacy-expected.conf}
  '';
}
