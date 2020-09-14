{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    wayland.windowManager.sway = {
      enable = true;

      config = {
        focus.followMouse = "always";
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
        sway-unwrapped =
          pkgs.runCommandLocal "dummy-sway-unwrapped" { version = "1"; }
          "mkdir $out";
        swaybg = pkgs.writeScriptBin "dummy-swaybg" "";
        xwayland = pkgs.writeScriptBin "xwayland" "";
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.config/sway/config
      assertFileContent home-files/.config/sway/config \
        ${./sway-followmouse-expected.conf}
    '';
  };
}
