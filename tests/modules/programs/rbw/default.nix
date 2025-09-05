{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  rbw-empty-settings = ./empty-settings.nix;
  rbw-simple-settings = ./simple-settings.nix;
  rbw-settings = ./settings.nix;
}
