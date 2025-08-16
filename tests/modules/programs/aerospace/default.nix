{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  aerospace = ./aerospace.nix;
  aerospace-colemak = ./aerospace-colemak.nix;
}
