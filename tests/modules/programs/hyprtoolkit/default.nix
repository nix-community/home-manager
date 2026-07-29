{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  hyprtoolkit-empty-config = ./empty-config.nix;
  hyprtoolkit-example-config = ./example-config.nix;
}
