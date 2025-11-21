{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  protonmail-bridge-basic-configuration = ./basic-configuration.nix;
  protonmail-bridge-empty-settings = ./empty-settings.nix;
}
