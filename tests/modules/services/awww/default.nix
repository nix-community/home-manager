{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  awww-graphical-session-target = ./awww-graphical-session-target.nix;
  awww-swww-package = ./awww-swww-package.nix;
}
