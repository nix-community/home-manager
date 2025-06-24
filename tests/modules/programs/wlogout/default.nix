{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  wlogout-styling = ./styling.nix;
  wlogout-layout-single = ./layout-single.nix;
  wlogout-layout-multiple = ./layout-multiple.nix;
}
