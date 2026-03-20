{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  satty-basic-configuration = ./basic-configuration.nix;
  satty-empty-configuration = ./empty-settings.nix;
}
