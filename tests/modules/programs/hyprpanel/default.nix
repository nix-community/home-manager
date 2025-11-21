{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  hyprpanel-basic-config = ./basic-config.nix;
  hyprpanel-with-hypridle = ./with-hypridle.nix;
}
