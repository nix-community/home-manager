{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  mpd-mpris-configuration-basic = ./configuration-basic.nix;
  mpd-mpris-configuration-with-local-mpd = ./configuration-with-local-mpd.nix;
  mpd-mpris-configuration-with-password = ./configuration-with-password.nix;
}
