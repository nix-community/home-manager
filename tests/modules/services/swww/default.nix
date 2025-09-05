{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  swww-graphical-session-target = ./swww-graphical-session-target.nix;
}
