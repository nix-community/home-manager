{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  cliphist-sway-session-target = ./cliphist-sway-session-target.nix;
  cliphist-extra-options = ./cliphist-extra-options.nix;
  cliphist-multiple-session-targets = ./cliphist-multiple-session-targets.nix;
}
