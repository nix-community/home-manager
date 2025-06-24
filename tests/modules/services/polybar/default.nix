{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  polybar-basic-configuration = ./basic-configuration.nix;
  polybar-empty-configuration = ./empty-configuration.nix;
}
