{ config, lib, ... }:

with lib;

{
  config = {
    xsession.windowManager.i3 = {
      enable = true;

      config.bars = [{
        colors.focusedBackground = "#ffffff";
        colors.focusedStatusline = "#000000";
        colors.focusedSeparator = "#999999";
      }];
    };

    nixpkgs.overlays = [ (import ./i3-overlay.nix) ];

    nmt.script = ''
      assertFileExists home-files/.config/i3/config
      assertFileContent home-files/.config/i3/config \
        ${./i3-bar-focused-colors-expected.conf}
    '';
  };
}
