{ config, lib, pkgs, ... }:

with lib;

let

  dummy-package = pkgs.runCommandLocal "dummy-package" { } "mkdir $out";

in {
  config = {
    # Enables the default bar configuration
    home.stateVersion = "20.09";

    wayland.windowManager.sway = {
      enable = true;
      package = null;
      config.menu = "${pkgs.dmenu}/bin/dmenu_run";
    };

    nixpkgs.overlays = [ (import ./sway-overlay.nix) ];

    assertions = [{
      assertion =
        !elem config.wayland.windowManager.sway.config.bars [ [ { } ] [ ] ];
      message =
        "The default Sway bars configuration should be set for this test (sway-null-package) to work.";
    }];

    nmt.script = ''
      assertFileExists home-files/.config/sway/config
      assertFileContent home-files/.config/sway/config \
        ${./sway-null-package.conf}
    '';
  };
}
