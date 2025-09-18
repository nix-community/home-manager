{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  wleave-styling = ./styling.nix;
  wleave-layout-single = ./layout-single.nix;
  wleave-layout-multiple = ./layout-multiple.nix;
}
