{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  clipse-sway-session-target = ./clipse-sway-session-target.nix;
}
