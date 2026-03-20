{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  signaturepdf-basic-configuration = ./basic-configuration.nix;
}
