{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  flameshot-empty-settings = ./empty-settings.nix;
  flameshot-example-settings = ./example-settings.nix;
}
