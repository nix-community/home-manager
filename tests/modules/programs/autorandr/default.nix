{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  autorandr-basic-configuration = ./basic-configuration.nix;
  autorandr-scale = ./scale.nix;
}
