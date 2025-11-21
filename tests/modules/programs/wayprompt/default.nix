{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  wayprompt-empty-settings = ./empty-settings.nix;
  wayprompt-example-settings = ./example-settings.nix;
}
