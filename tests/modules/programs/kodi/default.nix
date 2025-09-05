{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  kodi-example-addon-settings = ./example-addon-settings.nix;
  kodi-example-settings = ./example-settings.nix;
  kodi-example-sources = ./example-sources.nix;
}
