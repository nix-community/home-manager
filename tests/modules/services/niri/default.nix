{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  niri-minimal = ./niri-minimal.nix;
  niri-empty = ./niri-empty.nix;
}
