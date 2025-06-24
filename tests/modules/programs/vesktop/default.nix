{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  vesktop-basic-configuration = ./basic-configuration.nix;
}
