{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  voxtype-basic-configuration = ./basic-configuration.nix;
}
