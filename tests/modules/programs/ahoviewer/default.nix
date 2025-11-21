{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  ahoviewer-example-config = ./example-config.nix;
}
