{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  swayimg-empty-settings = ./empty-settings.nix;
  swayimg-example-settings = ./example-settings.nix;
}
