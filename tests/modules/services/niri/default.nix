{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  niri-empty-config = ./niri-empty-config.nix;
  niri-example-settings = ./niri-example-settings.nix;
  niri-default-config = ./niri-default-config.nix;
  niri-default-config-package-null = ./niri-default-config-package-null.nix;
}
