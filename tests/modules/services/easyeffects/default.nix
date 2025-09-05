{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  easyeffects-service = ./service.nix;
  easyeffects-example-preset = ./example-preset.nix;
}
