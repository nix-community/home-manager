{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  hyprland-qt-support-basic-configuration = ./basic-configuration.nix;
}
