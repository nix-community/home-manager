{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  bemenu-empty-configuration = ./empty-configuration.nix;
  bemenu-basic-configuration = ./basic-configuration.nix;
}
