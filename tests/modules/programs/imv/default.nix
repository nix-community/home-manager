{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  imv-basic-configuration = ./basic-configuration.nix;
  imv-empty-configuration = ./empty-configuration.nix;
}
