{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  dunst-with-settings = ./with-settings.nix;
  dunst-without-settings = ./without-settings.nix;
}
