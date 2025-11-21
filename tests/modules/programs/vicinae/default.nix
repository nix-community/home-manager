{ lib, pkgs, ... }:
lib.optionalAttrs (pkgs.stdenv.hostPlatform.isLinux) {
  vicinae-example-settings = ./example-settings.nix;
}
