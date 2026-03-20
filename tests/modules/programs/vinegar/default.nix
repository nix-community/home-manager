{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  vinegar-empty-settings = ./empty-settings.nix;
  vinegar-example-settings = ./example-settings.nix;
}
