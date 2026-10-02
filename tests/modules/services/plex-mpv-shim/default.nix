{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  plex-mpv-shim-basic-configuration = ./basic-configuration.nix;
  plex-mpv-shim-mutable-settings = ./mutable-settings.nix;
  plex-mpv-shim-custom-path-package = ./custom-path-package.nix;
  plex-mpv-shim-empty-settings = import ./no-settings.nix { enable = true; };
  plex-mpv-shim-empty-mutable-settings = import ./no-settings.nix {
    enable = true;
    mutableSettings = true;
  };
  plex-mpv-shim-disabled = import ./no-settings.nix { enable = false; };
}
