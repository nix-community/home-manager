{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  kanshi-new-configuration = ./new-configuration.nix;
  kanshi-alias-assertion = ./alias-assertion.nix;
  kanshi-empty-settings = ./empty-settings.nix;
}
