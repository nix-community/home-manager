{ config, lib, pkgs, ... }:

{
  imports = [ ./sway-stubs.nix ];

  # Enables the default bar configuration
  home.stateVersion = "20.09";

  wayland.windowManager.sway = {
    enable = true;
    package = null;
    checkConfig = false;
    config.menu = "${pkgs.dmenu}/bin/dmenu_run";
  };

  assertions = [{
    assertion =
      !lib.elem config.wayland.windowManager.sway.config.bars [ [ { } ] [ ] ];
    message =
      "The default Sway bars configuration should be set for this test (sway-null-package) to work.";
  }];

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
    assertFileContent $(normalizeStorePaths home-files/.config/sway/config) \
      ${./sway-null-package.conf}
  '';
}
