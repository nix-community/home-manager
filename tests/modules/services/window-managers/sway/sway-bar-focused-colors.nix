{ config, lib, pkgs, ... }:

{
  imports = [ ./sway-stubs.nix ];

  wayland.windowManager.sway = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@sway@"; };
    checkConfig = false;
    # overriding findutils causes issues
    config.menu = "${pkgs.dmenu}/bin/dmenu_run";

    config.bars = [{
      colors.focusedBackground = "#ffffff";
      colors.focusedStatusline = "#000000";
      colors.focusedSeparator = "#999999";
    }];
  };

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
    assertFileContent $(normalizeStorePaths home-files/.config/sway/config) \
      ${./sway-bar-focused-colors.conf}
  '';
}
