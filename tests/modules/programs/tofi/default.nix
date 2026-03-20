{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  tofi-basic-configuration = ./basic-configuration.nix;
}
