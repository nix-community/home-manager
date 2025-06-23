{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  kanshi-basic-configuration = ./basic-configuration.nix;
  kanshi-new-configuration = ./new-configuration.nix;
  kanshi-alias-assertion = ./alias-assertion.nix;
}
