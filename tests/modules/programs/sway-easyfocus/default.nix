{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  sway-easyfocus-example-config = ./example-config.nix;
}
