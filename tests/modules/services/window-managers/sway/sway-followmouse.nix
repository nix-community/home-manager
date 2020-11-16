{ config, lib, pkgs, ... }:

with lib;

let

  dummy-package = pkgs.runCommandLocal "dummy-package" { } "mkdir $out";

in {
  config = {
    wayland.windowManager.sway = {
      enable = true;
      package = dummy-package // { outPath = "@sway"; };

      config = {
        focus.followMouse = "always";
        menu = "${pkgs.dmenu}/bin/dmenu_run";
        bars = [ ];
      };
    };

    nixpkgs.overlays = [
      (self: super: {
        dmenu = dummy-package // { outPath = "@dmenu@"; };
        rxvt-unicode-unwrapped = dummy-package // {
          outPath = "@rxvt-unicode-unwrapped@";
        };
        sway = dummy-package // { outPath = "@sway@"; };
        sway-unwrapped = dummy-package // { version = "1"; };
        swaybg = dummy-package // { outPath = "@swaybg@"; };
        xwayland = dummy-package // { outPath = "@xwayland@"; };
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.config/sway/config
      assertFileContent home-files/.config/sway/config \
        ${./sway-followmouse-expected.conf}
    '';
  };
}
