{ config, lib, pkgs, ... }:

{
  imports = [ ./sway-stubs.nix ];

  wayland.windowManager.sway = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@sway@"; };
    checkConfig = false;
    # overriding findutils causes issues
    config.menu = "${pkgs.dmenu}/bin/dmenu_run";
    config.defaultWorkspace = "workspace number 9";
  };

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
    assertFileContent $(normalizeStorePaths home-files/.config/sway/config) \
      ${./sway-workspace-default-expected.conf}
  '';
}
