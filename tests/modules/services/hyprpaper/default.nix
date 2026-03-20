{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  hyprpaper-basic-configuration = ./basic-configuration.nix;
  hyprpaper-no-configuration = ./no-configuration.nix;
}
