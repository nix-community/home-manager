{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    wayland.windowManager.sway = {
      enable = true;

      config = {
        focus.followMouse = false;
        menu = "${pkgs.dmenu}/bin/dmenu_run";
        bars = [ ];
      };
    };

    nixpkgs.overlays = [
      (self: super: {
        dmenu = super.dmenu // { outPath = "@dmenu@"; };
        rxvt-unicode-unwrapped = super.rxvt-unicode-unwrapped // {
          outPath = "@rxvt-unicode-unwrapped@";
        };
        sway = super.sway // { outPath = "@sway@"; };
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.config/sway/config
      assertFileContent home-files/.config/sway/config \
        ${./sway-followmouse-legacy-expected.conf}
    '';
  };
}
