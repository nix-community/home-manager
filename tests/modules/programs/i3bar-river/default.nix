{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  i3bar-river-example-config = ./example-config.nix;
}
