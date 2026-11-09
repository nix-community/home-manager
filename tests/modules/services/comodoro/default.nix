{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  comodoro-service = ./comodoro.nix;
  comodoro-service-defaults = ./comodoro-defaults.nix;
}
