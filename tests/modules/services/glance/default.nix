{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  glance-default-settings = ./default-settings.nix;
  glance-example-settings = ./example-settings.nix;
}
