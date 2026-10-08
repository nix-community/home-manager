{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  eww-basic-configuration = ./basic-configuration.nix;
  eww-empty-settings = ./empty-settings.nix;
}
