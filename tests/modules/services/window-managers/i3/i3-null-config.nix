{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    xsession.windowManager.i3 = {
      enable = true;
      config = null;
    };

    nixpkgs.overlays = [ (import ./i3-overlay.nix) ];

    nmt.script = ''
      assertFileExists home-files/.config/i3/config
      assertFileContent home-files/.config/i3/config \
        ${pkgs.writeText "expected" "\n"}
    '';
  };
}
