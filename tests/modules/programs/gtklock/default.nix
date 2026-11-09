{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  gtklock-config = ./gtklock-config.nix;
  gtklock-empty-config = ./gtklock-empty-config.nix;
}
