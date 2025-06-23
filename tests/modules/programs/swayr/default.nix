{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  swayr-basic-configuration = ./basic-configuration.nix;
  swayr-empty-configuration = ./empty-configuration.nix;
}
