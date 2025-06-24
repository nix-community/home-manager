{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  gnome-terminal-1 = ./gnome-terminal-1.nix;
  gnome-terminal-bad-profile-name = ./bad-profile-name.nix;
}
