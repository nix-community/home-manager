{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  hyprshot-basic-configuration = ./basic-configuration.nix;
}
