{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  syshud-default = ./syshud-default.nix;
  syshud-settings = ./syshud-settings.nix;
}
