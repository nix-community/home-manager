{ lib, pkgs, ... }:
lib.optionalAttrs (pkgs.stdenv.hostPlatform.isLinux) {
  vicinae-package-null = ./package-null.nix;

  vicinae-pre17-settings = ./pre17-settings.nix;
  vicinae-example-settings = ./example-settings.nix;
}
