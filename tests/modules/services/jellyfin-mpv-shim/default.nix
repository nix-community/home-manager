{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  jellyfin-mpv-shim-example-settings = ./example-settings.nix;
}
