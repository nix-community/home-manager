{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  home-manager-auto-upgrade-basic-configuration = ./basic-configuration.nix;
  home-manager-auto-upgrade-flake-configuration = ./flake-configuration.nix;
}
