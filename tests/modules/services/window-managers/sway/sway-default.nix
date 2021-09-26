{ config, lib, pkgs, ... }:

{
  imports = [ ./sway-stubs.nix ];

  wayland.windowManager.sway = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@sway@"; };
    # overriding findutils causes issues
    config.menu = "${pkgs.dmenu}/bin/dmenu_run";
  };

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
    assertFileContent home-files/.config/sway/config \
      ${./sway-default.conf}
  '';
}
