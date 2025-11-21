{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  avizo-with-settings = ./with-settings.nix;
  avizo-without-settings = ./without-settings.nix;
}
