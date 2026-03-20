{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  aerospace = ./aerospace.nix;
  aerospace-no-xdg = ./aerospace-no-xdg.nix;
  aerospace-settings = ./aerospace-settings.nix;
  aerospace-settings-no-xdg = ./aerospace-settings-no-xdg.nix;
}
