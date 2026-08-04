{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  rift-wm = ./normal.nix;
  rift-wm-settings = ./settings.nix;
}
