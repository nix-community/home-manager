{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  hyprscratch-empty-settings = ./empty-settings.nix;
  hyprscratch-example-settings = ./example-settings.nix;
  hyprscratch-valid-settings = ./valid-settings.nix;
}
