{ config, lib, pkgs, ... }:

{
  imports = [ ./sway-stubs.nix ];

  wayland.windowManager.sway = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@sway@"; };
    config = null;
    systemdIntegration = false;
  };

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
    assertFileContent home-files/.config/sway/config \
      ${pkgs.writeText "expected" "\n"}
  '';
}
