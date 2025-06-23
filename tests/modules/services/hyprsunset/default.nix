{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  hyprsunset-basic-configuration = ./basic-configuration.nix;
}
