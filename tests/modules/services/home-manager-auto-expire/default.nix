{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  home-manager-auto-expire-basic-configuration = ./basic-configuration.nix;
}
