{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  picom-basic-configuration = ./picom-basic-configuration.nix;
}
