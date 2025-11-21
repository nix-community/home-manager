{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  polkit-gnome-basic-configuration = ./basic-configuration.nix;
}
