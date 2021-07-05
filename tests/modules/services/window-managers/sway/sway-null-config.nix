{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    wayland.windowManager.sway = {
      enable = true;
      config = null;
      systemdIntegration = false;
      package = pkgs.sway;
    };

    nixpkgs.overlays = [ (import ./sway-overlay.nix) ];

    nmt.script = ''
      assertFileExists home-files/.config/sway/config
      assertFileContent home-files/.config/sway/config \
        ${pkgs.writeText "expected" "\n"}
    '';
  };
}
