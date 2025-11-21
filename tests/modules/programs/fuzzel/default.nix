{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  fuzzel-example-settings = ./example-settings.nix;
  fuzzel-empty-settings = ./empty-settings.nix;
}
