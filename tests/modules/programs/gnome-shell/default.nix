{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  gnome-shell = ./gnome-shell.nix;
}
