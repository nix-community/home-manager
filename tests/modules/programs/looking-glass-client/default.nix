{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  looking-glass-client-example-settings = ./example-settings.nix;
  looking-glass-client-empty-settings = ./empty-settings.nix;
}
