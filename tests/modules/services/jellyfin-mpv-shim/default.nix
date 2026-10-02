{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  jellyfin-mpv-shim-example-settings = ./example-settings.nix;
  jellyfin-mpv-shim-manual-settings = ./manual-settings.nix;
  jellyfin-mpv-shim-empty-settings = ./empty-settings.nix;
  jellyfin-mpv-shim-disabled = ./disabled.nix;
}
