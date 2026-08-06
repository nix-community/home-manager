{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  pinnacle-basic-configuration = ./basic-configuration.nix;
}
