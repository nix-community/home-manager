{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  hyprlock-basic-configuration = ./basic-configuration.nix;
  hyprlock-complex-configuration = ./complex-configuration.nix;
}
