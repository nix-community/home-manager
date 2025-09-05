{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  pantalaimon-basic-configuration = ./basic-configuration.nix;
}
