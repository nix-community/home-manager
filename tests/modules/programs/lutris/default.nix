{ lib, pkgs, ... }:
lib.optionalAttrs (pkgs.stdenv.hostPlatform.isx86_64 && pkgs.stdenv.hostPlatform.isLinux) {
  lutris-runners = ./runners-configuration.nix;
  # lutris-wine = ./wine-configuration.nix;
  lutris-empty = ./empty.nix;
}
