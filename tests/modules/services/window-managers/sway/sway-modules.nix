{ config, lib, pkgs, ... }:

with lib;

let

  dummy-package = pkgs.runCommandLocal "dummy-package" { } "mkdir $out";

in {
  config = {
    wayland.windowManager.sway = {
      enable = true;
      package = dummy-package // { outPath = "@sway"; };
      # overriding findutils causes issues
      config = {
        menu = "${pkgs.dmenu}/bin/dmenu_run";

        input = { "*" = { xkb_variant = "dvorak"; }; };
        output = { "HDMI-A-2" = { bg = "~/path/to/background.png fill"; }; };
        seat = { "*" = { hide_cursor = "when-typing enable"; }; };
      };
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

    nmt.script = ''
      assertFileExists home-files/.config/sway/config
      assertFileContent home-files/.config/sway/config \
        ${./sway-modules.conf}
    '';
  };
}
