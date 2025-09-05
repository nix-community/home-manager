{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  yambar-empty-settings = ./empty-settings.nix;
  yambar-example-settings = ./example-settings.nix;
}
