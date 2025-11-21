{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  rofi-pass-root = ./rofi-pass-root.nix;
  rofi-pass-config = ./rofi-pass-config.nix;
}
