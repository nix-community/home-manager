{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  home-manager-auto-upgrade-basic-configuration = ./basic-configuration.nix;
}
