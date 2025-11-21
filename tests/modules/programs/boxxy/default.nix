{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  boxxy-empty-settings = ./empty-settings.nix;
  boxxy-example-settings = ./example-settings.nix;
}
