{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  trayscale-show-window = ./show-window.nix;
  trayscale-hide-window = ./hide-window.nix;
}
