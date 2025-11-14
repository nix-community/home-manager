{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  aerospace = ./aerospace.nix;
  aerospace-settings = ./aerospace-settings.nix;
}
