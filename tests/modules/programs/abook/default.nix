{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  abook-no-settings = ./no-settings.nix;
  abook-with-settings = ./with-settings.nix;
}
