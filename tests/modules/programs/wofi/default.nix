{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  wofi-basic-configuration = ./basic-configuration.nix;
  wofi-empty-configuration = ./empty-configuration.nix;
  wofi-style-local-file = ./style-local-file.nix;
}
