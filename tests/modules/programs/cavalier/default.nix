{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  cavalier-general-settings = ./cavalier-general-settings.nix;
  cavalier-cava-settings = ./cavalier-cava-settings.nix;
}
