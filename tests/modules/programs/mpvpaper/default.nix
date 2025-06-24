{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  mpvpaper-example-config = ./example-config.nix;
}
