{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  clipman-sway-session-target = ./clipman-sway-session-target.nix;
}
