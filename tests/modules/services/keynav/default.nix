{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  keynav-enable = ./enable.nix;
  keynav-extra-config = ./extra-config.nix;
}
