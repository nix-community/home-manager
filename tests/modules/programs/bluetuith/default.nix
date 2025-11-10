{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  bluetuith-empty-settings = ./empty-settings.nix;
  bluetuith-example-settings = ./example-settings.nix;
}
