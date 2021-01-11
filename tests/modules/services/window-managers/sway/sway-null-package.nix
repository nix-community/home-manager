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

    nixpkgs.overlays = [
      (self: super: {
        dmenu = dummy-package // { outPath = "@dmenu@"; };
        rxvt-unicode-unwrapped = dummy-package // {
          outPath = "@rxvt-unicode-unwrapped@";
        };
        i3status = dummy-package // { outPath = "@i3status@"; };
        sway = dummy-package // { outPath = "@sway@"; };
        xwayland = dummy-package // { outPath = "@xwayland@"; };
      })
    ];

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
